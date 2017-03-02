import Queue
import threading
import requests

def publish_notifications(grprefix, duration, rate, nrpairs=1):
    def _publ_notifications(rqueue, grid, duration, rate)
        data = """<input xmlns="tag:opendaylight.org,2017:controller:yang:lowlevel:control">
  <id>$ID</id>
  <seconds>$DURATION</seconds>
  <notifications-per-second>$RATE</notifications-per-second>
</input>"""
        try:
            resp = requests.post(url='/restconf/operations/odl-mdsal-lowlevel-control:publish-notifications')
        except requests.Timeout as exc:
            resp = exc
        rqueue.put(resp)

    resqueue = Queue.Queue()
    lthreads = []
    for i in range(nrpairs):
        t = threading.Thread(target=_publ_notifications, args = (resqueue, "{}{}".format(grprefix, i+1), duration, rate))
        t.daemon = True
        t.start()
        lthreads.append(t)

    for t in lthreads:
        t.join()
