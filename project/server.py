import asyncio
import aiohttp
import sys
import json
import time

server_communication = {
	'Goloman': ['Hands', 'Holiday', 'Wilkes'],
	'Hands': ['Goloman', 'Wilkes'],
	'Holiday': ['Goloman', 'Welsh', 'Wilkes'],
	'Welsh': ['Holiday'],
	'Wilkes': ['Goloman', 'Hands', 'Holiday']
}

server_ports = {
	'Goloman': 12050 ,
	'Hands': 12051,
	'Holiday': 12052,
	'Welsh': 12053,
	'Wilkes': 12054
}

myAPIkey = 'AIzaSyDnH8iw0kPMSZi1fFOj2iG_VJw0VioUMe0'

clients = {}

def get_lat_long(input):
	instances = []
	for i in range(len(input)):
		if input[i] == '+' or input[i] == '-':
			instances.append(i)


	if len(instances) != 2:
		return None

	if instances[0] != 0:
		return None

	if instances[1] == len(input) - 1:
		return None
	lat_long = None
	try:
		lat_long = float(input[:instances[1]]), float(input[instances[1]:])
	except:
		pass
	return lat_long

async def flood_fill(msg, server_name):
	for s in server_communication[server_name]:
		log_file.write("Attempting to open connection with server {0} at port {1}...".format(s, server_ports[s]))
		try:
			reader, writer = await asyncio.open_connection('127.0.0.1', port_dict[s], loop=loop)
			log_file.write("Success\n")
			writer.write(msg.encode())
			await writer.drain()
			writer.close()
		except:
			log_file.write("Fail\n")
			pass

def valid_input(msg):
	if len(msg) < 1:
		return -1
	if msg[0] == "IAMAT":
		if len(msg) == 4:
			if get_lat_long(msg[2]) is not None:
				time = None
				try:
					time = float(msg[3])
				except:
					pass
				if time is None:
					return -1
				return 1
			else:
				return -1
		else:
			return -1
	elif msg[0] == "WHATSAT":
		if len(msg) == 4:
			rad = None
			try:
				rad = float(msg[2])
			except:
				pass
			if rad is None:
				return -1
			elif rad > 50 or rad <= 0:
				return -1
			else:
				num_entries = None
				try:
					num_entries = int(msg[3])
				except:
					pass
				if num_entries is None:
					return -1
				elif num_entries > 20 or num_entries <= 0:
					return -1
				else:
					return 2
		else:
			return -1

	elif msg[0] == "CHANGELOC":
		if len(msg) == 6:
			return 3
		else:
			return -1
	else:
		return -1

def process_iamat(msg_arr, time_received):
	if get_lat_long(msg_arr[2]) is None:
		return None
	return [msg_arr[0], msg_arr[1], msg_arr[2], msg_arr[3], str(time_received), sys.argv[1]]

async def generate_output(in_msg, time_received):
    message = in_msg.strip().split()
    out_msg = ""
    error_msg = "? {0}".format(in_msg)
    message_type = valid_input(message)
	# IAMAT
    if message_type == 1:
        # Update the client dictionary with new location
        msg_info = process_iamat(message, time_received)
        if msg_info is not None:
			# Store location, reported client time, time received by server
            clients[message[1]] = msg_info
            time_diff = time_received - float(message[3])
            if time_diff > 0:
                time_diff = "+" + str(time_diff)
            out_msg = ("AT {0} {1} {2}\n".format(sys.argv[1], time_diff, ' '.join(message[1:])))
			# Send CHANGELOC messages to all connected servers
            asyncio.ensure_future(flood_fill('CHANGELOC {0}\n'.format(' '.join(msg_info[1:])), sys.argv[1]))
        else:
            out_msg = error_msg

    elif message_type == 2:
        if message[1] not in clients:
            out_msg = "??? {0}".format(in_msg)
        else:
            client = clients[message[1]]
            loc = get_lat_long(client[2])
            loc = str(loc[0]) + "," + str(loc[1])
            rad = float(message[2]) * 1000
            url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?key={0}&location={1}&radius={2}'.format(myAPIkey, loc, rad)
            time_diff = float(client[4]) - float(client[3])

            if time_diff > 0:
                time_diff = "+" + str(time_diff)
                out_msg = "AT {0} {1} {2} {3} {4}\n".format(client[5], time_diff, client[1], client[2], client[3])

                async with aiohttp.ClientSession() as session:
                    async with session.get(url) as resp:
                        response = await resp.json()
                        response['results'] = response['results'][:int(message[3])]
                        out_msg += json.dumps(response, indent=3)
                        out_msg += "\n\n"
    else:
        out_msg = error_msg
    return out_msg

async def handle_input(reader, writer):
    data = await reader.readline()
    time_received = time.time()
    in_msg = data.decode()
	# The data already ends in a newline
    log_file.write("Receive: " + in_msg)

	# Format the message to be in list form
    message = in_msg.strip().split()
	# The CHANGELOC case is handled independently since there is no output to the client/other servers when received
    if message[0] == "CHANGELOC" and valid_input(message):
		# Check if the time in the message was sent later than the time currently in the dict
        if message[1] not in clients:
            clients[message[1]] = message
            asyncio.ensure_future(flood_fill('CHANGELOC {0}\n'.format(' '.join(message[1:])), sys.argv[1]))
        else:
			# This location came after the one currently stored in the dictionary
			# Don't floodfill if this is the second time you've received the message
            if message[3] > clients[message[1]][3]:
                clients[message[1]] = message
                asyncio.ensure_future(flood_fill('CHANGELOC {0}\n'.format(' '.join(message[1:])), sys.argv[1]))
    else:
        out_msg = await generate_output(in_msg, time_received)
        log_file.write("SENDING: " + out_msg)
        writer.write(out_msg.encode())
        await writer.drain()

def main():

    if len(sys.argv) != 2:
        print("Usage: python3 server.py server_name")
        exit()
    srv = sys.argv[1]
    try: port = server_ports[srv]
    except:
        print("Error: Server name does not exist.")
        exit()

    global log_file
    log_file = open(sys.argv[1] + "_log.txt", "w+")

    global loop

    loop = asyncio.get_event_loop()

    coro = asyncio.start_server(handle_input, '127.0.0.1', server_ports[sys.argv[1]], loop=loop)

    server = loop.run_until_complete(coro)

    try:
        loop.run_forever()
    except KeyboardInterrupt:
        pass

    log_file.write('Closing server.\n\n')
    server.close()
    loop.run_until_complete(server.wait_closed())
    loop.close()
    log_file.close()


if __name__ == '__main__':
	main()
