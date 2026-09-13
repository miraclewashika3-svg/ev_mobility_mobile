package com.evmobility.rider

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not FlutterActivity -- local_auth's Android
// implementation shows the biometric prompt via a Fragment, which requires
// the host Activity to be a FragmentActivity.
class MainActivity : FlutterFragmentActivity()
