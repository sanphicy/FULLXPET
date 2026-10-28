import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraVideoWidget extends StatefulWidget {
  final String deviceId;
  final bool isTestMode;

  const AgoraVideoWidget({Key? key, required this.deviceId, this.isTestMode = true}) : super(key: key);

  @override
  State<AgoraVideoWidget> createState() => _AgoraVideoWidgetState();
}

class _AgoraVideoWidgetState extends State<AgoraVideoWidget> {
  RtcEngine? _engine;
  int? _remoteUid; // 记录远端用户

  static const String _testAppId = "ad5962d89caf429f8daf7f716c8b8360";
  static const String _testToken =
      "007eJxTYFhxnfnux61iXxTjJt5wf3v1me6G6txG8Z25O/w/7Nv9wfSxAkNiiqmlmVGKhWVyYpqJkWWaRUpimnmauaFZskWShbGZQeSBe1kNgYwMit2JDIxQCOIzMRgYMjAAACD4IaY=";
  static const String _testChannel = "01";

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(appId: _testAppId, channelProfile: ChannelProfileType.channelProfileLiveBroadcasting),
    );

    // 监听事件
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("===== 收到远端用户: $remoteUid =====");
          setState(() {
            _remoteUid = remoteUid; // 发现推流端，更新 UI
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("===== 远端用户离线: $remoteUid =====");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    await engine.enableVideo();
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);

    await engine.joinChannel(token: _testToken, channelId: _testChannel, uid: 0, options: const ChannelMediaOptions());

    if (mounted) {
      setState(() {
        _engine = engine;
      });
    }
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_engine == null) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF917CEE))),
      );
    }

    return Container(
      color: Colors.black,
      child: _remoteUid != null
          ? AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: _testChannel),
              ),
            )
          : const Center(
              child: Text('等待设备端推流...', style: TextStyle(color: Colors.white)),
            ),
    );
  }
}
