import os
import sys
import importlib
import defopt
import yaml

from PyQt5 import QtGui, uic
from PyQt5.QtCore import QThreadPool
from PyQt5.QtWidgets import QApplication, QMainWindow, QStyle
import qdarktheme

from gui_viewer import ViewerTab
from gui_settings import SettingsTab
from utils import find_version
from worker import Worker
from osc_handler import OSCStreamer

class DAQViewer(QMainWindow):
    def __init__(self, app=None, default_config=''):
        super().__init__()

        # Load default layout
        self.app = app
        self.default_config = default_config
        uic.loadUi('QtGUI/qt5main.ui', self)
        self.setWindowTitle("DAQViewer v{}".format(str(find_version('__init__.py'))))
        self.setWindowIcon(QtGui.QIcon('assets/mfh_logo.png'))
        self.app.aboutToQuit.connect(self.shutdown_task)

        self.config = self.read_settings(self.default_config)
        self.loadGUI(reload=False)

    def loadGUI(self, reload: bool):
        if reload:
            self.shutdown_task()
        self._initialize_info()
        self._initialize_addon()
        self.vt = ViewerTab(self.viewer, self.config)
        self.st = SettingsTab(self.settings, self.config, self.default_config, self)
        self.multidata_connector = self.vt.MultiDataConnector # dict

        # Initialize opensoundcontrol worker
        self.threadpool = QThreadPool()
        self.oscstream = OSCStreamer(config = self.config, 
                                      multidata_connector=self.multidata_connector,
                                      QtWindow=self)
        self.worker = Worker(self.oscstream.run)
        self.threadpool.start(self.worker)
        self.pause_task() # halt for now

    def _initialize_info(self):
        # https://doc.qt.io/qt-6/qstyle.html#StandardPixmap-enum
        start_pixmap = QStyle.StandardPixmap.SP_MediaPlay
        stop_pixmap = QStyle.StandardPixmap.SP_MediaStop

        self.StartButton.clicked.connect(self.start_task)
        self.StartButton.setIcon(self.style().standardIcon(start_pixmap))
        self.StartButton.setEnabled(True)

        self.StopButton.clicked.connect(self.pause_task)
        self.StopButton.setIcon(self.style().standardIcon(stop_pixmap))
        self.StopButton.setEnabled(False)

        self.osc_ipaddress = self.config['IPAddress']
        self.osc_port = self.config['Port']
        self.UDP.setText('udp//{}:{}'.format(self.osc_ipaddress,self.osc_port))

    def _initialize_addon(self):
        self.AddOnInfo.setTitle(self.config['Protocol'])
        if "AddOn" in self.config:
            addon_name = self.config["AddOn"].split(".")[0]
            addon = importlib.import_module('addons.{}'.format(addon_name))
            addon.DAQViewerAddOn(self.AddOnInfo, self.config)
        else:
            pass

    def start_task(self):
        for dc in self.multidata_connector.values():
            dc.resume() 
        self.StartButton.setEnabled(False)
        self.StopButton.setEnabled(True)
        if not self.LED.m_value:
            self.LED.toggleValue()

    def pause_task(self):
        for dc in self.multidata_connector.values():
            dc.pause() 

        self.StartButton.setEnabled(True)
        self.StopButton.setEnabled(False)
        if self.LED.m_value:
            self.LED.toggleValue()

    def shutdown_task(self):
        self.pause_task()
        self.worker.kill()
        self.oscstream.kill()

    def read_settings(self, fpath:str):
        with open(fpath) as stream:
            try:
                r = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc)

        print('Loading {} settings...'.format(r['Protocol']))
        return r

def main(default_config: str ='settings/dmdm.yaml'):
    """
    Launch DAQViewer GUI
    
    :param str default_config: path to default setting file
    """
    qdarktheme.enable_hi_dpi()
    app = QApplication(sys.argv)
    qdarktheme.setup_theme()

    win = DAQViewer(app, default_config = os.path.abspath(default_config))
    win.show()
    print('DAQViewer started successfully!')
    try:
        sys.exit(app.exec_())
    finally:
        print('DAQViewer closed successfully!')

if __name__ == '__main__':
    defopt(main())