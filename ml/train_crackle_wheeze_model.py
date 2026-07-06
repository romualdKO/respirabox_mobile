"""Entraîne un CNN léger détecteur de crackles/sibilants sur ICBHI 2017,
puis l'exporte en TFLite pour inférence embarquée dans l'app Flutter.

Sortie: modèle multi-label 2 sorties sigmoïdes [P(crackle), P(wheeze)].

Usage:
    python train_crackle_wheeze_model.py --data-dir data/ --out ../assets/models/crackle_wheeze_model.tflite
"""
import argparse
from pathlib import Path

import numpy as np
import tensorflow as tf
from sklearn.metrics import roc_auc_score, classification_report


def build_model(input_shape):
    inputs = tf.keras.Input(shape=input_shape)
    x = tf.keras.layers.Reshape((*input_shape, 1))(inputs)

    x = tf.keras.layers.Conv2D(16, 3, padding="same", activation="relu")(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.MaxPooling2D()(x)

    x = tf.keras.layers.Conv2D(32, 3, padding="same", activation="relu")(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.MaxPooling2D()(x)

    x = tf.keras.layers.Conv2D(64, 3, padding="same", activation="relu")(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)

    x = tf.keras.layers.Dropout(0.3)(x)
    x = tf.keras.layers.Dense(32, activation="relu")(x)
    outputs = tf.keras.layers.Dense(2, activation="sigmoid", name="crackle_wheeze")(x)

    return tf.keras.Model(inputs, outputs)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--epochs", type=int, default=30)
    args = parser.parse_args()

    train = np.load(args.data_dir / "train.npz")
    test = np.load(args.data_dir / "test.npz")
    X_train, y_train = train["X"], train["y"]
    X_test, y_test = test["X"], test["y"]

    print(f"Train: {X_train.shape}  Test: {X_test.shape}")

    model = build_model(X_train.shape[1:])
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="binary_crossentropy",
        metrics=[tf.keras.metrics.AUC(name="auc", multi_label=True)],
    )
    model.summary()

    # Pondération de classe : crackles/wheezes sont minoritaires par cycle
    n_pos_crackle = y_train[:, 0].sum()
    n_pos_wheeze = y_train[:, 1].sum()
    n_total = len(y_train)
    print(f"Prévalence train — crackles: {n_pos_crackle}/{n_total}  wheezes: {n_pos_wheeze}/{n_total}")

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_auc", mode="max", patience=6, restore_best_weights=True
        ),
    ]

    model.fit(
        X_train,
        y_train,
        validation_data=(X_test, y_test),
        epochs=args.epochs,
        batch_size=32,
        callbacks=callbacks,
        verbose=2,
    )

    # Évaluation finale
    y_pred = model.predict(X_test)
    for i, label in enumerate(["crackles", "wheezes"]):
        try:
            auc = roc_auc_score(y_test[:, i], y_pred[:, i])
            print(f"\n=== {label} — AUC: {auc:.3f} ===")
        except ValueError as e:
            print(f"\n=== {label} — AUC non calculable: {e} ===")
        print(classification_report(y_test[:, i], (y_pred[:, i] > 0.5).astype(int)))

    # Export TFLite (float16 pour réduire la taille sur mobile)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_model = converter.convert()
    args.out.write_bytes(tflite_model)
    print(f"\n✅ Modèle TFLite exporté: {args.out} ({len(tflite_model) / 1024:.1f} KB)")


if __name__ == "__main__":
    main()
