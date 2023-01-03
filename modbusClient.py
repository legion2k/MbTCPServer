# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------------------------------------------------------------------
import asyncio
from queue import Queue
import datetime
#-------------------------------------------------------------------------------------------------------------------------------------
class ClientProtocol(asyncio.Protocol):
    def __init__(self, on_con_lost, mesQueue):
        self.__on_con_lost = on_con_lost
        self.__queue = mesQueue

    def connection_made(self, transport):
        print(datetime.datetime.now(), 'Connected')
        self.__transport = transport

    def data_received(self, data):
        print(datetime.datetime.now(),'Data received: {!r}'.format(data))
        self.__queue.put_nowait(data)

    def connection_lost(self, exc):
        print(datetime.datetime.now(),'The server closed the connection')
        self.__on_con_lost.set_result(True)
        self.__queue.put_nowait(None)

async def connectTo(host,port):
    mesQueue = asyncio.Queue()
    loop = asyncio.get_running_loop()
    on_con_lost = loop.create_future()
    try:
        transport, protocol = await asyncio.wait_for( loop.create_connection(
            host=host,
            port=port,
            protocol_factory = lambda: ClientProtocol(on_con_lost, mesQueue),
        ), timeout=3)
    except Exception as e:
        print(e)
        return
    data = ''
    i=0;
    while True:
        # чистим очередь
        while not mesQueue.empty():
            data = mesQueue.get_nowait()
            if data is None:
                break
        if data is None: break
        #await asyncio.sleep(0.5)
        
        transport.write( bytes([0,0, 0,0, 0,6, 1,3, 0,0, 0,125]) );print(datetime.datetime.now(),'wite')
        #transport.write( bytes([]) );

        i += 1
        #if i>10:
            #print ('break')
            #break
        try:
            data = await mesQueue.get()
            #data = await asyncio.wait_for( mesQueue.get(),  timeout=1 )
            if data is None:
                break
        except asyncio.TimeoutError:
            print('asyncio.TimeoutError')
    try:
        await on_con_lost
    finally:
        transport.close()

    print('---------')

async def main():
    tsk=[ asyncio.create_task(connectTo('127.0.0.1',502)) for _ in range(100) ]
    for t in tsk: 
        await t    
    print('++++++++++++')

asyncio.run(main())
