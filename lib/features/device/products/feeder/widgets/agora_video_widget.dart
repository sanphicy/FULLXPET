import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:fullxpet/features/device/products/feeder/models/feeder_live_info.dart';

class AgoraVideoWidget extends StatefulWidget {
  final FeederLiveInfo? liveInfo;
  final bool isLoading;
  final String errorMsg;
  final VoidCallback? onRetry;

  const AgoraVideoWidget({super.key, required this.liveInfo, this.isLoading = false, this.errorMsg = '', this.onRetry});

  @override
  State<AgoraVideoWidget> createState() => _AgoraVideoWidgetState();
}

class _AgoraVideoWidgetState extends State<AgoraVideoWidget> {
  RtcEngine? _engine;
  int? _remoteUid;
  String _currentChannel = '';

  @override
  void initState() {
    super.initState();
    if (widget.liveInfo != null && widget.liveInfo!.isValid) {
      _initAgora(widget.liveInfo!);
    }
  }

  @override
  void didUpdateWidget(covariant AgoraVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newInfo = widget.liveInfo;
    if (newInfo != null && newInfo.isValid && newInfo.token != oldWidget.liveInfo?.token) {
      _initAgora(newInfo);
    }
  }

  Future<void> _initAgora(FeederLiveInfo info) async {
    await _releaseEngine();
    _currentChannel = info.channelName;

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(appId: info.appId, channelProfile: ChannelProfileType.channelProfileLiveBroadcasting),
    );

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("===== 收到远端用户加入: $remoteUid =====");
          // 优先绑定第一个加入的设备端（若已有画面则不被后进入的手机端覆盖）
          if (mounted && _remoteUid == null) {
            setState(() => _remoteUid = remoteUid);
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("===== 远端用户离线: $remoteUid =====");
          // 只有当前正在观看的设备离线时，才清空画面
          if (mounted && _remoteUid == remoteUid) {
            setState(() => _remoteUid = null);
          }
        },
      ),
    );

    // 开启视频模块以接收远端画面，但关闭本地摄像头采集（不启用手机相机）
    await engine.enableVideo();
    await engine.enableLocalVideo(false);
    await engine.enableLocalAudio(false);

    // 关键：使用 Broadcaster 角色进房，触发设备端 onUserJoined 唤醒推流
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await engine.joinChannel(
      token: info.token,
      channelId: info.channelName,
      uid: info.uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        // 只作为激活端与接收端，不推送手机自身的摄像头和麦克风流
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );

    if (mounted) {
      setState(() => _engine = engine);
    }
  }

  Future<void> _releaseEngine() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _remoteUid = null;
    }
  }

  @override
  void dispose() {
    _releaseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || (widget.liveInfo != null && _engine == null)) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF917CEE))),
      );
    }

    if (widget.liveInfo == null || !widget.liveInfo!.isValid) {
      return Container(
        color: Colors.black,
        child: Center(
          child: GestureDetector(
            onTap: widget.onRetry,
            child: Text(
              widget.errorMsg.isNotEmpty ? '${widget.errorMsg} (点击重试)' : '获取直播失败，点击重试',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: _remoteUid != null
          ? AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: _currentChannel),
              ),
            )
          : const Center(
              child: Text('等待设备端推流...', style: TextStyle(color: Colors.white)),
            ),
    );
  }
}
