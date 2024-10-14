import numpy as np
import matplotlib.pyplot as plt

save_file_location_ai = './test_ai.bin'

arr = np.fromfile(save_file_location_ai, dtype=np.float64) # Needs to be float64!
plt.plot(arr)
plt.show()

# If you want to save npy file...
# np.save('./file.npy', arr)