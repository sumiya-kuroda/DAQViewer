from pythonosc.udp_client import SimpleUDPClient

ip = "127.0.0.1"
port = "8888"

client = SimpleUDPClient(ip, int(port))  # Create client

client.send_message("/achn1", 1) 