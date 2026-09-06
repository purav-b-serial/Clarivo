package com.clarivo.app

import io.flutter.embedding.android.FlutterActivity

/**
 * Main Android entry point for Clarivo.
 *
 * All platform-channel logic (thermal state, notification callbacks, etc.)
 * is handled via Flutter plugin method channels registered by the respective
 * Flutter plugins (flutter_local_notifications, etc.).
 *
 * No custom platform code is required in this file for the initial release.
 */
class MainActivity : FlutterActivity()
