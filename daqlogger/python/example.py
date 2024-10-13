from pythonosc.udp_client import SimpleUDPClient

ip = "127.0.0.1"
port = "59729"

client = SimpleUDPClient(ip, int(port))  # Create client

while True:
    client.send_message("/ai1", 1) 