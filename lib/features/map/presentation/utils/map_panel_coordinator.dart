/// Coordinates mutually exclusive Map presentation panels without touching map data.
class MapPanelCoordinator {
  bool _vehicleListVisible = false;
  bool _detailsSuppressed = false;

  bool get vehicleListVisible => _vehicleListVisible;

  bool shouldShowVehicleSheet(bool hasSelectedVehicle) =>
      hasSelectedVehicle && !_vehicleListVisible && !_detailsSuppressed;

  void openVehicleList() {
    _vehicleListVisible = true;
    _detailsSuppressed = true;
  }

  void closeVehicleList() {
    _vehicleListVisible = false;
  }

  void selectVehicle() {
    _vehicleListVisible = false;
    _detailsSuppressed = false;
  }

  void selectMarker() {
    _vehicleListVisible = false;
    _detailsSuppressed = false;
  }
}
