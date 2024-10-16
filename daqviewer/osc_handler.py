import time
from typing import Any
from utils import normalize_angle_np

from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import ThreadingOSCUDPServer

def print_handler(address, *args):
    print(f"{address}: {args}")

class OSCStreamer(object):
    def __init__(self, config=None, multidata_connector=None, QtWindow=None, **kwargs):
        super().__init__()

        self.config = config
        self.server_address = (self.config['IPAddress'],int(self.config['Port']))
        self.multidata_connector = multidata_connector
        self.QtWindow = QtWindow
        self._initialize_dispatcher()
        self.server = ThreadingOSCUDPServer(self.server_address,self.dispatcher)

    def _initialize_dispatcher(self) -> None:
        self.dispatcher = Dispatcher()
        for k,v in  self.config['Inputs'].items():
            # self.dispatcher.map("/{}".format(k), print_handler)
            self.dispatcher.map("/{}".format(k), self._connectTTLEvent)
        self.dispatcher.map("/expid", self._getExperimentID)
        # self.dispatcher.map("/expid", print_handler)

    def _connectTTLEvent(self, address: str, *args: Any) -> None:
        # TODO check float or int
        # Check that address starts with filter
        if not address[0] == "/":  # Check syntax
            return

        value = args[0]
        if 'ctr0' in address: # because ctr0 will be running wheel
            value = normalize_angle_np(value)
        else:
            pass

        self.multidata_connector[address[1:]].cb_append_data_point(value, time.time())

    def _getExperimentID(self, address: str, *args: str) -> None:
        # Check that address starts with filter
        if not address[0] == "/":  # Check syntax
            return

        value = args[0]
        self.QtWindow.ExperimentID.setText(value)

    def run(self):
        print('Launching python-osc server...')
        self.server.serve_forever()

    def kill(self):
        self.server.shutdown() # stop
        self.server.server_close() # clean up