"""Prétraitement du dataset ICBHI 2017 Respiratory Sound Database.

Segmente chaque enregistrement en cycles respiratoires individuels (via les
fichiers d'annotation .txt fournis par ICBHI), extrait un log-mel-spectrogramme
par cycle, et sauvegarde les features + labels (crackles/wheezes) séparés
selon le split officiel train/test du challenge.

⚠️ Contexte important (voir ml/README.md) : ce dataset est enregistré au
stéthoscope numérique posé sur le thorax, pas au micro de smartphone sur une
toux volontaire. Le modèle entraîné sur ces données sert de détecteur de
crackles/sibilants (signal auxiliaire), pas de diagnostic TB/pneumonie direct.

Usage:
    python prepare_icbhi_data.py --raw-dir /path/to/ICBHI_final_database --out-dir data/
"""
import argparse
import csv
from pathlib import Path

import librosa
import numpy as np
from tqdm import tqdm

SAMPLE_RATE = 4000  # Hz — suffisant pour crackles/wheezes (RespireNet, Ntalampiras et al.)
CYCLE_DURATION_S = 5.0  # durée fixe par cycle (pad/crop) — couvre la grande majorité des cycles ICBHI
N_MELS = 64
N_FFT = 256
HOP_LENGTH = 64


def load_annotation(txt_path: Path):
    cycles = []
    with open(txt_path) as f:
        for row in csv.reader(f, delimiter="\t"):
            if len(row) < 4:
                continue
            start, end, crackle, wheeze = row[:4]
            cycles.append((float(start), float(end), int(float(crackle)), int(float(wheeze))))
    return cycles


def extract_log_mel(segment: np.ndarray) -> np.ndarray:
    target_len = int(SAMPLE_RATE * CYCLE_DURATION_S)
    if len(segment) < target_len:
        segment = np.pad(segment, (0, target_len - len(segment)))
    else:
        segment = segment[:target_len]

    mel = librosa.feature.melspectrogram(
        y=segment, sr=SAMPLE_RATE, n_fft=N_FFT, hop_length=HOP_LENGTH, n_mels=N_MELS
    )
    log_mel = librosa.power_to_db(mel, ref=np.max)
    # Normalisation par échantillon (0-1) pour stabiliser l'entraînement
    log_mel = (log_mel - log_mel.min()) / (log_mel.max() - log_mel.min() + 1e-8)
    return log_mel.astype(np.float32)


def load_split(raw_dir: Path):
    split_map = {}
    with open(raw_dir / "ICBHI_challenge_train_test.txt") as f:
        for row in csv.reader(f, delimiter="\t"):
            if len(row) < 2:
                continue
            split_map[row[0]] = row[1].strip()
    return split_map


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-dir", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    split_map = load_split(args.raw_dir)

    features = {"train": [], "test": []}
    labels = {"train": [], "test": []}  # [crackle, wheeze]

    txt_files = sorted(
        p
        for p in args.raw_dir.glob("*.txt")
        if p.stem not in ("filename_differences",)
    )

    for txt_path in tqdm(txt_files, desc="Fichiers"):
        recording_id = txt_path.stem
        wav_path = args.raw_dir / f"{recording_id}.wav"
        if not wav_path.exists():
            continue
        split = split_map.get(recording_id)
        if split not in ("train", "test"):
            continue

        cycles = load_annotation(txt_path)
        audio, _ = librosa.load(wav_path, sr=SAMPLE_RATE, mono=True)

        for start, end, crackle, wheeze in cycles:
            start_idx = int(start * SAMPLE_RATE)
            end_idx = int(end * SAMPLE_RATE)
            segment = audio[start_idx:end_idx]
            if len(segment) < SAMPLE_RATE * 0.1:  # cycle trop court, ignoré
                continue

            log_mel = extract_log_mel(segment)
            features[split].append(log_mel)
            labels[split].append([crackle, wheeze])

    for split in ("train", "test"):
        X = np.stack(features[split])
        y = np.array(labels[split], dtype=np.float32)
        np.savez_compressed(args.out_dir / f"{split}.npz", X=X, y=y)
        n_crackle = int(y[:, 0].sum())
        n_wheeze = int(y[:, 1].sum())
        print(f"{split}: {len(X)} cycles — crackles={n_crackle} wheezes={n_wheeze} — shape={X.shape}")


if __name__ == "__main__":
    main()
