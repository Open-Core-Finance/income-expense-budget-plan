import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission widget containing information about the passed [Permission]
class PermissionWidget extends StatefulWidget {
  final Permission permission;

  /// Constructs a [PermissionWidget] for the supplied [Permission]
  const PermissionWidget({super.key, required this.permission});

  @override
  State<PermissionWidget> createState() => _PermissionState();
}

class _PermissionState extends State<PermissionWidget> {
  late Permission _permission;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _permission = widget.permission;
    _listenForPermissionStatus();
  }

  void _listenForPermissionStatus() async {
    final status = await _permission.status;
    setState(() => _permissionStatus = status);
  }

  Color getPermissionColor() {
    switch (_permissionStatus) {
      case PermissionStatus.denied:
        return Colors.red;
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.limited:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(_permission.toString(), style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(_permissionStatus.toString(), style: TextStyle(color: getPermissionColor())),
      trailing: (_permission is PermissionWithService)
          ? IconButton(
              icon: const Icon(Icons.info, color: Colors.white),
              onPressed: () => checkServiceStatus(context, (_permission as PermissionWithService)))
          : null,
      onTap: () => requestPermission(_permission),
    );
  }

  void checkServiceStatus(BuildContext context, PermissionWithService permission) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((await permission.serviceStatus).toString())));
  }

  Future<void> requestPermission(Permission permission) async {
    final status = await permission.request();

    setState(() {
      _permissionStatus = status;
    });
  }
}
