from daqmx_recorder import DAQLogger

save_file_location_ai = './test_ai.bin'
save_file_location_ci = './test_ci.bin'
        
print('\nRunning demo for DAQLogger\n\n')

Logger = DAQLogger(ai_channels=['ai0', 'ai1'],
                    ci_channels = 'ctr0',
                    sample_rate = 9000,
                    sample_size = 1000, 
                    osc_ip = "127.0.0.1",
                    osc_port = "59729",
                    osc_address_ai = ['/ai0', '/ai1'],
                    osc_address_ci = ['/ctr0'],
                    save_file_location_ai = save_file_location_ai,
                    save_file_location_ci = save_file_location_ci)
Logger.start_acquisition()
input('press return to stop')
Logger.stop_acquisition()
Logger.close_tasks()