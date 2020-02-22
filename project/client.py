import asyncio
import time


async def setup_tcp_client(message, loop):

    reader, writer = await asyncio.open_connection('127.0.0.1', 12050, loop=loop)
    print("Sending:", message, end="")
    writer.write(message.encode())
    data = await reader.read(10000)
    print("Received:", data.decode(), end="")
    writer.close()

def main():
    #message = "IAMAT kiwi.cs.ucla.edu +34.068930-118.445127 1520023934.918963997"
    message = "WHATSAT kiwi.cs.ucla.edu 10 5\n"
    loop = asyncio.get_event_loop()
    loop.run_until_complete(setup_tcp_client(message, loop))
    loop.close()

if __name__ == '__main__':
    main()
