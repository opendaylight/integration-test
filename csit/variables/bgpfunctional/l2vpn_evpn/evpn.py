main_template='''<evpn-route xmlns="urn:opendaylight:params:xml:ns:yang:bgp-evpn">
        <route-key>evpn1</route-key>
        <route-distinguisher>429496729:1</route-distinguisher>
        EVPN_NLRI
        <attributes>
          <ipv4-next-hop>
           <global>199.20.166.41</global>
          </ipv4-next-hop><as-path/>
          <origin>
           <value>igp</value>
          </origin>
          EXTENDED_COMUNITIES
         </attributes>
      </evpn-route>'''


_nlri = { '_eth': '''<ethernet-a-d-route>
    <mpls-label>24001</mpls-label>
    <ethernet-tag-id>
        <vlan-id>10</vlan-id>
    </ethernet-tag-id>
    EVPN_ESI
</ethernet-a-d-route>''',
    '_mac': '''<mac-ip-adv-route>
    EVPN_ESI
    <ethernet-tag-id>
        <vlan-id>10</vlan-id>
    </ethernet-tag-id>
    <mac-address>f2:0c:dd:80:9f:f7</mac-address>
    <ip-address>43.43.43.43</ip-address>
    <mpls-label1>24002</mpls-label1>
    <mpls-label2>24003</mpls-label2>
</mac-ip-adv-route>''',
    '_inc': '''<inc-multi-ethernet-tag-res>
    <ethernet-tag-id>
        <vlan-id>10</vlan-id>
    </ethernet-tag-id>
    <orig-route-ip>43.43.43.43</orig-route-ip>
</inc-multi-ethernet-tag-res>''',
    '_es': '''<es-route>
    <orig-route-ip>43.43.43.43</orig-route-ip>
    EVPN_ESI
</es-route>'''
}


_esi = { '_lacp':'''<lacp-auto-generated>
    <ce-lacp-mac-address>f2:0c:dd:80:9f:f7</ce-lacp-mac-address>
    <ce-lacp-port-key>22</ce-lacp-port-key>
</lacp-auto-generated>''',
    '_arb': '''<arbitrary>
    <arbitrary>ABCD</arbitrary>
</arbitrary>''',
    '_lan': '''<lan-auto-generated>
    <root-bridge-mac-address>f2:0c:dd:80:9f:f7</root-bridge-mac-address>
    <root-bridge-priority>20</root-bridge-priority>
</lan-auto-generated>''',
    '_mac' : '''<mac-auto-generated>
    <system-mac-address>f2:0c:dd:80:9f:f7</system-mac-address>
    <local-discriminator>2000</local-discriminator>
</mac-auto-generated>''',
   '_rou': '''<router-id-generated>
    <router-id>43.43.43.43</router-id>
    <local-discriminator>2000</local-discriminator>
</router-id-generated>''',
   '_as': '''<as-generated>
    <as>16843009</as>
    <local-discriminator>2000</local-discriminator>
</as-generated>'''
}

_extended_comunities = { '_extesilab': '''<extended-communities>
        <transitive>true</transitive>
        <esi-label-extended-community>
            <single-active-mode>true</single-active-mode>
            <esi-label>24001</esi-label>
        </esi-label-extended-community >
    </extended-communities>''',
   '_extesr': '''<extended-communities>
        <transitive>false</transitive>
        <es-import-route-extended-community>
            <es-import>f2:0c:dd:80:9f:f7</es-import>
        </es-import-route-extended-community>
    </extended-communities>''',
   '_extmac': '''<extended-communities>
        <transitive>true</transitive>
        <mac-mobility-extended-community>
            <static>true</static>
            <seq-number>200</seq-number>
        </mac-mobility-extended-community>
    </extended-communities>''',
    '_extdef': '''<extended-communities>
        <transitive>false</transitive>
        <default-gateway-extended-community>
        </default-gateway-extended-community>
    </extended-communities>''',
    '_extl2': '''<extended-communities>
        <transitive>true</transitive>
        <layer-2-attributes-extended-community>
            <primary-pe>true</primary-pe>
            <backup-pe>true</backup-pe>
            <control-word >true</control-word>
            <l2-mtu>200</l2-mtu>
        </layer-2-attributes-extended-community>
    </extended-communities>'''
}



import xml
import pprint
import json
import os
#xml = xml.dom.minidom.parse(xml_fname) # or xml.dom.minidom.parseString(xml_string)
#pretty_xml_as_string = xml.toprettyxml()

url='http://localhost:8181/restconf/config/bgp-rib:application-rib/example-app-rib/tables/odl-bgp-evpn:l2vpn-address-family/odl-bgp-evpn:evpn-subsequent-address-family/odl-bgp-evpn:evpn-routes/'
import requests
def get_variables():
    for knlri, vnlri in _nlri.iteritems():
        a = main_template.replace('EVPN_NLRI', vnlri).replace('EXTENDED_COMUNITIES','')
        for kesi, vesi in _esi.iteritems():
            b = a.replace('EVPN_ESI', vesi)
            fname = 'route{}{}'.format(knlri,kesi)
            print fname, b
            with open(fname, 'wt') as f:
                f.write(b)
            xml1 = xml.dom.minidom.parse(fname)
            ptext =  xml1.toprettyxml()
            ptext = "\n".join([ll.rstrip() for ll in ptext.splitlines() if ll.strip()])
            with open('{}.xml'.format(fname), 'wt') as f:
                f.write(ptext)
            rsp = requests.delete(url, auth=('admin','admin'))
            rsp = requests.post(url, data=ptext, headers={'content-type':'application/xml'}, auth=('admin','admin'))
            print rsp
            rsp = requests.get(url, auth=('admin','admin'))
            print rsp.content
            with open('{}.json'.format(fname),'wt') as f:
                j = json.loads(rsp.content)
                f.write(json.dumps(j, indent=2))
                #pprint.pprint(j,f)
            rsp = requests.delete(url, auth=('admin','admin'))
            print rsp
            with open('announce_{}.hex'.format(fname),'wt') as f:
                f.write('ffffffffffffffffffffffffffffffff001304')
            with open('withdraw_{}.hex'.format(fname),'wt') as f:
                f.write('ffffffffffffffffffffffffffffffff001304')

            
    for kext, vext in _extended_comunities.iteritems():
        knlri = '_eth'
        kesi = '_lacp'
        a = main_template.replace('EVPN_NLRI', _nlri[knlri]).replace('EVPN_ESI', _esi[kesi]).replace('EXTENDED_COMUNITIES',vext)
        fname = 'route{}{}{}'.format(knlri,kesi,kext)
        print fname, a
        with open(fname, 'wt') as f:
            f.write(a)
        xml1 = xml.dom.minidom.parse(fname)
        ptext =  xml1.toprettyxml()
        ptext = "\n".join([ll.rstrip() for ll in ptext.splitlines() if ll.strip()])
        print ptext
        with open('{}.xml'.format(fname), 'wt') as f:
            f.write(ptext)
        rsp = requests.delete(url, auth=('admin','admin'))
        rsp = requests.post(url, data=ptext, headers={'content-type':'application/xml'}, auth=('admin','admin'))
        print rsp
        rsp = requests.get(url, auth=('admin','admin'))
        print rsp.content
        with open('{}.json'.format(fname),'wt') as f:
            j = json.loads(rsp.content)
            f.write(json.dumps(j, indent=2))
            #pprint.pprint(j,f)
        rsp = requests.delete(url, auth=('admin','admin'))
        print rsp
        with open('announce_{}.hex'.format(fname),'wt') as f:
            f.write('ffffffffffffffffffffffffffffffff001304')
        with open('withdraw_{}.hex'.format(fname),'wt') as f:
            f.write('ffffffffffffffffffffffffffffffff001304')


def rem_newlines():
    files = os.listdir(".")
    for f in files:
        if ".hex" not in f:
            continue
        with open(f,'rt') as fd:
            cnt = fd.read()
        if cnt[-1] == '\n':
            cnt = cnt[:-1]
        else:
            continue
        print "updating", f, cnt
        with open(f,'wt') as fd:
            cnt = fd.write(cnt)
