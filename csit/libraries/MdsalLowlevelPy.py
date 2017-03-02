import Queue
import requests
import string
import threading

def publish_notifications(host, grprefix, duration, rate, nrpairs=1):
    """Invoke publish notification rpc.

    :param host: ip address of odl node
    :type host: string
    :param grprefix: prefix identifier for publisher/listener pair
    :type grprefix: string
    :param duration: publishing notification duration in seconds
    :type duration: int
    :param rate: events rate per second
    :type rate: int
    :param nrpairs: number of publisher/listener pairs, id suffix is counted from it
    :type nrpairs: int
    """

    def _publ_notifications(rqueue, url, grid, duration, rate)
        dtmpl = string.Template('''<input xmlns="tag:opendaylight.org,2017:controller:yang:lowlevel:control">
  <id>$ID</id>
  <seconds>$DURATION</seconds>
  <notifications-per-second>$RATE</notifications-per-second>
</input>''')
        data = dtmpl.substitute({'ID': grid, 'DURATION': duration, 'RATE': rate})
        try:
            resp = requests.post(url=url, headers={'Content-Type': 'application/xml'},
                           data=data, auth=('admin', 'admin')
        except requests.Timeout as exc:
            resp = exc
        rqueue.put(resp)

    resqueue = Queue.Queue()
    lthreads = []
    url = 'http://{}:8181/restconf/operations/odl-mdsal-lowlevel-control:publish-notifications'.format(host)
    for i in range(nrpairs):
        t = threading.Thread(target=_publ_notifications, args = (resqueue, url, '{}{}'.format(grprefix, i+1), duration, rate))
        t.daemon = True
        t.start()
        lthreads.append(t)

    for t in lthreads:
        t.join()
