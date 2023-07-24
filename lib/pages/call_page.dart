import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../service/notification_service.dart';

const appId = "b26db13351364858b6f208f3d0b904f4";
const token = "007eJxTYEhUC3LRmLPz6DOJrX9d2mpWLHBxuyZ1bSrDj5dvmFn7nzIpMCQZmaUkGRobmxoam5lYmFokmaUZGVikGacYJFkamKSZKMdsTWkIZGQ4l+LNysgAgSA+M0NyhiEDAwAPBh38";
const channel = "ch1";

class callPage extends StatefulWidget {
  final bool isCaller;
  final String callType;

  const callPage({Key? key, required this.isCaller, required this.callType})
      : super(key: key);

  @override
  State<callPage> createState() => _CallPageState();
}

class _CallPageState extends State<callPage> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = false;
  bool _callEnded = false;
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    initAgora();

    if (widget.callType == "Audio call") {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    // create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
            print("local user here");
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
            _callEnded = true;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: channel,
      uid: widget.isCaller ? 0 : 1, // Use different UIDs for caller and receiver
      options: const ChannelMediaOptions(),
    );
  }

  // Create UI with local view and remote view
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D3FD3),
        title: const Text('Video Call'),
        actions: _callEnded
            ? [] // Empty list to remove the icons
            : [
          IconButton(
            onPressed: _onToggleMute,
            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
          ),
          IconButton(
            onPressed: _onSwitchCamera,
            icon: Icon(Icons.switch_camera),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: _callEnded
                ? const Text('Call ended')
                : widget.callType == "Audio call"
                ? _audioWidget()
                : _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 150,
              child: Center(
                child: _localUserJoined
                    ? widget.callType == "Video call"
                      ? AgoraVideoView(
                      controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: widget.isCaller ? 1 : 0),
                        ),
                      )
                      : SizedBox(width: 0)
                    : _remoteVideo(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _callEnded
          ? null // null to hide the button
          : Visibility(
        visible: !_callEnded,
        child: FloatingActionButton(
          onPressed: _onEndCall,
          backgroundColor: Colors.red,
          child: const Icon(Icons.call_end),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _onToggleMute() {
    if (_localUserJoined && _remoteUid != null) {
      setState(() {
        _isMuted = !_isMuted;
        _engine.muteLocalAudioStream(_isMuted);
      });
    }
  }

  void _onSwitchCamera() {
    if (_localUserJoined && _remoteUid != null) {
      setState(() {
        _engine.switchCamera();
      });
    }
  }

  void _onEndCall() {
    setState(() {
      _callEnded = true;
    });
    _engine.leaveChannel();
    _engine.release();
    Navigator.pop(context);
  }

  // Display local video preview
  Widget _localPreview() {
    if (_localUserJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Text(
        'Join a channel',
        textAlign: TextAlign.center,
      );
    }
  }

  // Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    } else {
      return const Text(
        'Ringing...',
        textAlign: TextAlign.center,
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _audioWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Audio Call',
          style: TextStyle(fontSize: 18),
        ),
        if (_remoteUid == null) ...[
          CircularProgressIndicator(),
          SizedBox(height: 10),
        ],
        Text(
          _formatTime(_secondsElapsed),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
