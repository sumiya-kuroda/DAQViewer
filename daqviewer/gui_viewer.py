import sys

from PyQt5.QtWidgets import QWidget, QGridLayout, QLabel, QScrollArea
from pglive.kwargs import Axis
from pglive.sources.live_axis import LiveAxis
from pglive.sources.data_connector import DataConnector
from pglive.sources.live_plot import LiveLinePlot
from pglive.sources.live_plot_widget import LivePlotWidget
from pglive.sources.live_axis_range import LiveAxisRange

class ViewerTab(QWidget):
    def __init__(self, parent=None, config=None, plot_rate=60,**kwargs):
        super().__init__(parent=parent, **kwargs)
        self.layout = QGridLayout()
        self.layout.setColumnStretch(2, 5)
        self.layout.setContentsMargins(0,0,0,0)
        self.layout.setSpacing(0)

        self.ndata = len(config['Inputs'].keys())
        self.update_rate = int(config['DAQSampleRate'] / config['DAQBufferSize'])
        self.plot_rate = plot_rate
        self.x_points_range = int(self.update_rate * config['Xrange_sec'])
        self.max_points = self.x_points_range
        self.plot_widgets = []
        self._MultiDataConnector = {}
        for i, (key, value) in enumerate(config['Inputs'].items()):
            print('Setting plotting area for {}: {}'.format(key,value['Label']))
            label_widget = QLabel(value['Label'])
            label_widget.setFixedSize(100, 60)
            # label_widget.setFont(QFont('Times', 10)) 
            plot_curve = LiveLinePlot()
            plot_widget = MiniLivePlotWidget(plot=plot_curve, 
                                              # x_range_controller=LiveAxisRange(roll_on_tick=self.x_points_range)),
                                              y_range=value['Yrange'] if "Yrange" in value else None)
            self.layout.addWidget(label_widget,i,0)
            self.layout.addWidget(plot_widget,i,1)
            self.plot_widgets.append(plot_widget)
            self._MultiDataConnector[key] = DataConnector(plot_curve, 
                                                            max_points=self.max_points, 
                                                            update_rate=self.update_rate,
                                                            plot_rate = self.plot_rate,
                                                            ignore_auto_range=False)

        for n in range(self.ndata)[:-1]:
            # self.plot_widgets[n].getPlotItem().hideAxis('bottom')
            self.plot_widgets[n].getAxis('bottom').setTextPen('#202124')
            self.plot_widgets[n].getAxis('bottom').setAxisPen('#202124')
            self.plot_widgets[n].setXLink(self.plot_widgets[-1])

        self.setLayout(self.layout)
        # TODO: make this scrollable

    @property
    def MultiDataConnector(self):
        return self._MultiDataConnector

    @MultiDataConnector.setter
    def MultiDataConnector(self, value):
        self._MultiDataConnector = value

class MiniLivePlotWidget(LivePlotWidget):
    def __init__(self, parent=None, plot=None, y_range=None, **kwargs):
        bottom_axis = LiveAxis("bottom", **{Axis.TICK_FORMAT: Axis.TIME})
        super().__init__(parent=parent, plot=plot, background='#202124', axisItems={'bottom': bottom_axis},
                         **kwargs)
        if y_range is not None:
            self.y_range_controller=LiveAxisRange(fixed_range=y_range)
        self.setFixedHeight(60)

        self.plot = plot
        self.addItem(self.plot)
