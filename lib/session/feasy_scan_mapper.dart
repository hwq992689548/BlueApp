import 'package:blue_app/session/scan_item.dart';
import 'package:blue_app/session/scan_kind.dart';
import 'package:feasy_blue_sdk/feasy_blue_sdk.dart';

ScanItem feasyScanToItem(FeasyBlueScanDevice d) => ScanItem(
      id: d.address,
      name: d.name,
      rssi: d.rssi,
      kind: ScanKind.feasy,
    );
