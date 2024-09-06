import os
from PyQt5.QtWidgets import QWidget, QFileDialog, QStyle

class SettingsTab(QWidget):
    def __init__(self, parent=None, config=None, config_path=None, QtWindow=None, **kwargs):
        super().__init__(parent=parent, **kwargs)


        self.config = config
        self.config_path = config_path
        self.QtWindow = QtWindow

        open_pixmap = QStyle.StandardPixmap.SP_DialogOpenButton
        load_pixmap = QStyle.StandardPixmap.SP_BrowserReload

        self.QtWindow.SettingDir.setText(os.path.abspath(self.config_path))
        self.QtWindow.OpenSettingButton.setIcon(self.style().standardIcon(open_pixmap))
        self.QtWindow.OpenSettingButton.setFixedWidth(30)
        self.QtWindow.OpenSettingButton.clicked.connect(self._select_data_dir)
        self.QtWindow.LoadSettingButton.setIcon(self.style().standardIcon(load_pixmap))
        self.QtWindow.LoadSettingButton.clicked.connect(self._apply_settings)

    def _select_data_dir(self):
        new_path, _ = QFileDialog.getOpenFileName(
            self, "Select config file", os.path.dirname(self.config_path),
            "YAML Files(*.yaml)"
        )
        if new_path != "":
            self.QtWindow.SettingDir.setText(os.path.abspath(new_path))
            self.config_path = new_path

    def _apply_settings(self):
        self.QtWindow.config = self.QtWindow.read_settings(self.config_path)
        self.QtWindow.loadGUI(reload=True)