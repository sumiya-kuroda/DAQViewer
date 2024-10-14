from daqmx_recorder import DAQLogger

class PyDAQLogger(DAQLogger):
    def __init__(self, 
                 save_file_location_ai,
                 save_file_location_ci, 
                 **kwargs):
        super().__init__(ai_channels=['ai0', 'ai1'],
                    ci_channels = 'ctr0',
                    sample_rate = 9000,
                    sample_size = 1000, 
                    osc_ip = "127.0.0.1",
                    osc_port = "59729",
                    osc_address_ai = ['/ai0', '/ai1'],
                    osc_address_ci = ['/ctr0'],
                    save_file_location_ai = save_file_location_ai,
                    save_file_location_ci = save_file_location_ci, 
                    **kwargs)