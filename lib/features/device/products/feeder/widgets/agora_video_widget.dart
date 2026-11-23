import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:fullxpet/features/device/models/feeder_live_info.dart';

class AgoraVideoWidget extends StatefulWidget {
  final bool isOnline;
  final FeederLiveInfo? liveInfo;
  final bool isLoading;
  final String errorMsg;
  final VoidCallback? onRetry;

  const AgoraVideoWidget({
    super.key,
    required this.isOnline,
    required this.liveInfo,
    this.isLoading = false,
    this.errorMsg = '',
    this.onRetry,
  });

  @override
  State<AgoraVideoWidget> createState() => _AgoraVideoWidgetState();
}

class _AgoraVideoWidgetState extends State<AgoraVideoWidget> {
  RtcEngine? _engine;
  int? _remoteUid;
  String _currentChannel = '';

  /// 串行互斥队列：保证声网原生单实例的创建、进房、离房、销毁绝不并发重入
  Future<void> _opChain = Future.value();
  int _initSeq = 0;
  bool _isDisposed = false;
  bool _isInitializing = false;
  String _engineError = '';

  @override
  void initState() {
    super.initState();
    if (widget.isOnline && widget.liveInfo != null && widget.liveInfo!.isValid) {
      _scheduleInit(widget.liveInfo!);
    }
  }

  @override
  void didUpdateWidget(covariant AgoraVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isOnline) {
      if (_engine != null || _isInitializing || _engineError.isNotEmpty || _remoteUid != null) {
        _scheduleRelease();
      }
      return;
    }

    final newInfo = widget.liveInfo;
    if (newInfo == null || !newInfo.isValid) {
      if (_engine != null || _isInitializing || _remoteUid != null) {
        _scheduleRelease();
      }
      return;
    }

    final bool paramsChanged =
        newInfo.token != oldWidget.liveInfo?.token ||
        newInfo.channelName != oldWidget.liveInfo?.channelName ||
        newInfo.uid != oldWidget.liveInfo?.uid;
    final bool recoveredOnline = !oldWidget.isOnline && _engine == null && !_isInitializing;
    final bool retriedSameToken = oldWidget.isLoading && !widget.isLoading && _engine == null && !_isInitializing;

    if (paramsChanged || recoveredOnline || retriedSameToken) {
      _scheduleInit(newInfo);
    }
  }

  Future<void> _enqueue(Future<void> Function() task) {
    final next = _opChain.then((_) => task()).catchError((Object e) {
      debugPrint('===== 声网任务队列异常: $e =====');
    });
    _opChain = next;
    return next;
  }

  void _scheduleInit(FeederLiveInfo info) {
    final int seq = ++_initSeq;
    _isInitializing = true;
    _engineError = '';
    _remoteUid = null;
    unawaited(_enqueue(() => _initAgoraInternal(info, seq)));
  }

  void _scheduleRelease() {
    _initSeq++;
    _isInitializing = false;
    _engineError = '';
    _remoteUid = null;
    unawaited(_enqueue(_releaseEngineInternal));
  }

  Future<void> _initAgoraInternal(FeederLiveInfo info, int seq) async {
    await _releaseEngineInternal();
    if (_isDisposed || !mounted || seq != _initSeq || !widget.isOnline) return;

    final String targetChannel = info.channelName;
    RtcEngine? createdEngine;
    bool hasJoined = false;

    try {
      createdEngine = createAgoraRtcEngine();
      await createdEngine.initialize(
        RtcEngineContext(appId: info.appId, channelProfile: ChannelProfileType.channelProfileLiveBroadcasting),
      );

      if (_isDisposed || !mounted || seq != _initSeq || !widget.isOnline) {
        await _disposeTempEngine(createdEngine, joined: false);
        return;
      }

      createdEngine.registerEventHandler(
        RtcEngineEventHandler(
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (connection.channelId != targetChannel) return;
            debugPrint('===== 收到远端用户加入: $remoteUid (channel: ${connection.channelId}) =====');
          },
          // 校验频道 ID，并仅当远端真正推送/解码视频流时绑定画面，避免多端同看误绑到其他手机
          onRemoteVideoStateChanged:
              (
                RtcConnection connection,
                int remoteUid,
                RemoteVideoState state,
                RemoteVideoStateReason reason,
                int elapsed,
              ) {
                if (connection.channelId != targetChannel) return;
                if (state == RemoteVideoState.remoteVideoStateStarting ||
                    state == RemoteVideoState.remoteVideoStateDecoding) {
                  if (!_isDisposed && mounted && seq == _initSeq && _remoteUid == null) {
                    debugPrint('===== 绑定远端视频流 UID: $remoteUid ($state) =====');
                    setState(() => _remoteUid = remoteUid);
                  }
                }
              },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (connection.channelId != targetChannel) return;
            debugPrint('===== 远端用户离线: $remoteUid (channel: ${connection.channelId}) =====');
            if (!_isDisposed && mounted && seq == _initSeq && _remoteUid == remoteUid) {
              setState(() => _remoteUid = null);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('===== 声网回调异常: $err, $msg =====');
          },
        ),
      );

      // 开启视频模块接收远端画面，关闭手机本地摄像头与麦克风采集
      await createdEngine.enableVideo();
      await createdEngine.enableLocalVideo(false);
      await createdEngine.enableLocalAudio(false);

      // 通过 ChannelMediaOptions 统一指定 Broadcaster 角色（触发设备端唤醒推流）且禁止发布本地流
      await createdEngine.joinChannel(
        token: info.token,
        channelId: targetChannel,
        uid: info.uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );
      hasJoined = true;

      if (_isDisposed || !mounted || seq != _initSeq || !widget.isOnline) {
        await _disposeTempEngine(createdEngine, joined: true);
        return;
      }

      setState(() {
        _engine = createdEngine;
        _currentChannel = targetChannel;
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('===== 声网初始化失败: $e =====');
      if (createdEngine != null) {
        await _disposeTempEngine(createdEngine, joined: hasJoined);
      }
      if (!_isDisposed && mounted && seq == _initSeq) {
        setState(() {
          _isInitializing = false;
          _engineError = '视频连接失败';
        });
      }
    }
  }

  Future<void> _disposeTempEngine(RtcEngine engine, {required bool joined}) async {
    if (joined) {
      try {
        await engine.leaveChannel();
      } catch (_) {}
    }
    try {
      await engine.release();
    } catch (_) {}
  }

  Future<void> _releaseEngineInternal() async {
    final engine = _engine;
    _engine = null;
    _currentChannel = '';
    if (_remoteUid != null) {
      if (!_isDisposed && mounted) {
        setState(() => _remoteUid = null);
      } else {
        _remoteUid = null;
      }
    }
    if (engine != null) {
      await _disposeTempEngine(engine, joined: true);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _initSeq++;
    unawaited(_enqueue(_releaseEngineInternal));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 设备离线：不拉流，显示深灰静默离线态
    if (!widget.isOnline) {
      return Container(
        color: const Color(0xFF1C1D24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle),
                child: const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 22),
              ),
              const SizedBox(height: 10),
              const Text('设备离线', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // 2. 拉流参数加载中 / 声网初始化中
    if (widget.isLoading || _isInitializing) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF917CEE))),
      );
    }

    // 3. 拉流或连接失败
    if (_engineError.isNotEmpty || widget.liveInfo == null || !widget.liveInfo!.isValid || _engine == null) {
      final tip = _engineError.isNotEmpty ? _engineError : (widget.errorMsg.isNotEmpty ? widget.errorMsg : '获取直播失败');
      return Container(
        color: Colors.black,
        child: Center(
          child: GestureDetector(
            onTap: widget.onRetry,
            child: Text('$tip，点击重试', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ),
      );
    }

    // 4. 正常播放 / 等待设备端推流
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
              child: Text('等待设备端推流...', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
    );
  }
}
