#!/usr/bin/env python
# coding:utf-8

import sys

PY3 = sys.version >= '3'
if not PY3:
    reload(sys).setdefaultencoding('utf-8')

import base64
import email.utils
import getopt
import hashlib
import json
import logging
import os
import re
import socket
import struct
import sys
import telnetlib
import threading
import time

if PY3:
    from urllib.request import urlopen, Request
    from queue import Queue
    from itertools import zip_longest
else:
    from urllib2 import urlopen, Request
    from Queue import Queue
    from itertools import izip_longest as zip_longest

logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)


def getip():
    urls = [
        'http://ip.3322.org',
        'http://whatismyip.akamai.com/',
        'http://checkip.amazonaws.com/',
    ]
    result = Queue()
    def _fetch(url):
        result.put(urlopen(Request(url, headers={'user-agent':'curl/7.53'}), timeout=5))
        logging.info('getip() from %r', url)
    for url in urls:
        t = threading.Thread(target=_fetch, args=(url,))
        t.setDaemon(True)
        t.start()
    text = result.get().read().decode()
    ip = re.search(r'(\d{1,3}.){3}\d{1,3}', text).group()
    return ip


def ipaddr(iface=''):
    if not iface:
        sock = socket.socket()
        sock = socket.socket(type=socket.SOCK_DGRAM)
        sock.connect(('8.8.8.8', 53))
        ip = sock.getsockname()[0]
        sock.close()
        return ip
    lines = os.popen('ip -o addr show {}'.format(iface)).read().splitlines()
    for line in lines:
        _, name, network, addr = line.strip().split()[:4]
        if network in (('inet', 'inet6')):
            return addr.split('/')[0]


def ddns_cx(api_key, api_secret, domain, ip=''):
    lip = socket.gethostbyname(domain)
    if ip == '':
        rip = getip()
    else:
        rip = ip
    if lip == rip:
        logging.info('remote ip and local ip is same to %s, exit.', lip)
        return
    api_url = 'https://www.cloudxns.net/api2/ddns'
    data = json.dumps({'domain': domain, 'ip': ip, 'line_id': '1'})
    date = email.utils.formatdate()
    api_hmac = hashlib.md5(''.join((api_key, api_url, data, date, api_secret)).encode()).hexdigest()
    headers = {'API-KEY': api_key, 'API-REQUEST-DATE': date, 'API-HMAC': api_hmac, 'API-FORMAT': 'json'}
    resp = urlopen(Request(api_url, data=data.encode(), headers=headers), timeout=5)
    logging.info('ddns_cx domain=%r to ip=%r result: %s', domain, ip, resp.read())


def ddns_cf(auth_email, auth_key, zone, record_name, ip=''):
    lip = socket.gethostbyname(record_name)
    if ip == '':
        ip = getip()
    if lip == ip:
        logging.info('remote ip and local ip is same to %s, exit.', lip)
        return
    headers = {'X-Auth-Email': auth_email, 'X-Auth-Key': auth_key, 'Content-Type': 'application/json'}
    if '.' not in zone:
        zone_name = zone
        zone_id = zone
    else:
        zone_name = zone
        api_url = 'https://api.cloudflare.com/client/v4/zones?name=%s' % zone_name
        resp = urlopen(Request(api_url, headers=headers), timeout=5)
        zone_id = json.loads(resp.read().decode())['result'][0]['id']
    if '.' not in record_name:
        record_id = record_name
    else:
        api_url = 'https://api.cloudflare.com/client/v4/zones/%s/dns_records?name=%s' % (zone_id, record_name)
        resp = urlopen(Request(api_url, headers=headers), timeout=5)
        record_id = json.loads(resp.read().decode())['result'][0]['id']
    api_url = 'https://api.cloudflare.com/client/v4/zones/%s/dns_records/%s' % (zone_id, record_id)
    data = json.dumps({'id': zone_id, 'type': 'A', 'ttl': 300, 'proxied': False, 'name': record_name, 'content': ip})
    req = Request(api_url, data=data.encode(), headers=headers)
    req.get_method = lambda: 'PUT'
    logging.info('ddns_cf updating record_name=%r to ip=%r', record_name, ip)
    resp = urlopen(req, timeout=5)
    logging.info('ddns_cf record_name=%r to ip=%r result: %s', record_name, ip, resp.read())


def ddns_gandi(api_key, zone, record_name, ip=''):
    lip = socket.gethostbyname(record_name)
    if ip == '':
        ip = getip()
    if lip == ip:
        logging.info('remote ip and local ip is same to %s, exit.', lip)
        return
    headers = {'X-Api-Key': api_key, 'Content-Type': 'application/json'}
    if '.' not in zone:
        zone_name = zone
        zone_id = zone
    else:
        zone_name = zone
        api_url = 'https://dns.api.gandi.net/api/v5/zones'
        resp = urlopen(Request(api_url, headers=headers), timeout=5)
        zone_id = next(x['uuid'] for x in json.loads(resp.read().decode()) if x['name'] == zone_name)
    if record_name.endswith(zone_name):
        record_name = record_name[:-len(zone_name)].strip('.')
    if record_name == '':
        record_name = '@'
    api_url = 'https://dns.api.gandi.net/api/v5/zones/%s/records/%s/A' % (zone_id, record_name)
    data = json.dumps({'rrset_ttl': 300, 'rrset_values': [ip]})
    req = Request(api_url, data=data.encode(), headers=headers)
    req.get_method = lambda: 'PUT'
    logging.info('ddns_gandi updating record_name=%r to ip=%r', record_name, ip)
    resp = urlopen(req, timeout=5)
    logging.info('ddns_gandi record_name=%r to ip=%r result: %s', record_name, ip, resp.read())


def aes_encrypt(key, iv):
    from Crypto.Cipher import AES
    text = sys.stdin.read()
    BS = AES.block_size
    pad = lambda s: s + (BS - len(s) % BS) * chr(BS - len(s) % BS)
    # unpad = lambda s : s[0:-ord(s[-1])]
    print(base64.b64encode(AES.new(key,  AES.MODE_CBC, iv).encrypt(pad(text))).decode())


def wol(mac='18:66:DA:17:A2:95', broadcast='192.168.2.255'):
    if len(mac) == 12:
        pass
    elif len(mac) == 12 + 5:
        mac = mac.replace(mac[2], '')
    else:
        raise ValueError('Incorrect MAC address format')
    data = ''.join(['FFFFFFFFFFFF', mac * 20])
    send_data = b''
    # Split up the hex values and pack.
    for i in range(0, len(data), 2):
        send_data = b''.join([send_data, struct.pack('B', int(data[i: i + 2], 16))])
    # Broadcast it to the LAN.
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    sock.sendto(send_data, (broadcast, 7))
    logging.info('wol packet sent to MAC=%r', mac)


def dnselect_cf(auth_email, auth_key, zone, record_name, iplist, port=443):
    lip = socket.gethostbyname(record_name)
    timeout = 3
    ips = iplist.split(',')
    timing = []
    for ip in ips:
        try:
            time_start = time.time()
            socket.create_connection((ip, port), timeout).close()
            timing.append(time.time() - time_start)
        except socket.error as e:
            logging.warning('connect(%r, %d) error: %s', ip, port, e)
            timing.append(timeout)
    mint, maxt = min(timing), max(timing)
    if timing[0] < 0.12 and lip != ips[0]:
        ip = ips[0]
        logging.info('dnselect_cf revert record_name=%r to ip=%s', record_name, ip)
    elif mint > 0.12:
        ip = ips[timing.index(mint)]
        logging.info('dnselect_cf elect record_name=%r to ip=%s', record_name, ip)
    else:
        logging.info('dnselect_cf skip record_name=%r to ip=%s', record_name, lip)
        return
    ddns_cf(auth_email, auth_key, zone, record_name, ip=ip)


def capture(url, wait_for_text='', selector='body', viewport_size='800x450', filename='capture.png'):
    """see https://hub.docker.com/r/phuslu/ghost.py/"""
    import ghost
    logging.info('create ghost.py Session')
    session = ghost.Session(ghost.Ghost(), viewport_size=tuple(map(int, viewport_size.split('x'))))
    logging.info('open %r', url)
    session.open(url)
    if wait_for_text:
        logging.info('wait_for_text %r', wait_for_text)
        session.wait_for_text(wait_for_text)
    else:
        logging.info('wait_for_page_loaded')
        session.wait_for_page_loaded()
    if '/' not in filename:
        filename = '/data/' + filename
    logging.info('capture selector=%r to %r', selector, filename)
    session.capture_to(filename, selector=selector)
    os.chmod(filename, 0o666)
    htmlfile = os.path.splitext(filename)[0] + '.html'
    open(htmlfile, 'wb').write(session.content.encode('utf-8'))
    os.chmod(htmlfile, 0o666)


def tcptop(pid=None, no_port=False, interval='1'):
    if not os.environ.get('WATCHED'):
        os.environ['WATCHED'] = '1'
        os.execv('/usr/bin/watch', ['watch', '-n' + interval, ' '.join(sys.argv)])
    lines = os.popen('ss -ntpi').read().splitlines()
    lines.pop(0)
    info = {}
    for i in range(0, len(lines), 2):
        line, next_line = lines[i], lines[i+1]
        state, _, _, laddr, raddr = line.split()[:5]
        apid = '-'
        comm = '-'
        if 'users:' in line:
            m = re.search(r'"(.+?)".+pid=(\d+)', line)
            comm, apid = m.group(1, 2)
        metrics = dict((k,int(v) if re.match(r'^\d+$', v) else v) for k, v in re.findall(r'([a-z_]+):(\S+)', next_line))
        bytes_acked = metrics.get('bytes_acked', 0)
        bytes_received = metrics.get('bytes_received', 0)
        if pid and apid != pid:
            continue
        if laddr.startswith(('127.', 'fe80::', '::1')) or raddr.startswith(('127.', 'fe80::', '::1')):
            continue
        if bytes_acked == 0 or bytes_received == 0:
            continue
        if not state.startswith('ESTAB'):
            continue
        laddr = laddr.lstrip('::ffff:')
        raddr = raddr.lstrip('::ffff:')
        if bytes_acked and bytes_received and state.startswith('ESTAB'):
            info[laddr, raddr] = (apid, comm, bytes_acked, bytes_received)
    if no_port:
        new_info = {}
        for (laddr, raddr), (pid, comm, bytes_acked, bytes_received) in info.items():
            laddr = laddr.rsplit(':', 1)[0].strip('[]').lstrip('::ffff:')
            raddr = raddr.rsplit(':', 1)[0].strip('[]').lstrip('::ffff:')
            try:
                parts = new_info[laddr, raddr]
                parts[-2] += bytes_acked
                parts[-1] += bytes_received
                new_info[laddr, raddr] = parts
            except KeyError:
                new_info[laddr, raddr] = [pid, comm, bytes_acked, bytes_received]
        info = new_info
    print("%-6s %-12s %-21s %-21s %6s %6s" % ("PID", "COMM", "LADDR", "RADDR", "RX_KB", "TX_KB"))
    infolist = sorted(info.items(), key=lambda x:(-x[1][-2], -x[1][-1]))
    for (laddr, raddr), (pid, comm, bytes_acked, bytes_received) in infolist:
        rx_kb  = bytes_received//1024
        tx_kb  = bytes_acked//1024
        if rx_kb == 0 or tx_kb == 0:
            continue
        print("%-6s %-12.12s %-21s %-21s %6d %6d" % (pid, comm, laddr, raddr, rx_kb, tx_kb))


def __main():
    applet = os.path.basename(sys.argv[0])
    funcs = [v for v in globals().values() if type(v) is type(__main) and v.__module__ == '__main__' and not v.__name__.startswith('_')]
    if not PY3:
        for func in funcs:
            setattr(func, '__doc__', getattr(func, 'func_doc'))
            setattr(func, '__defaults__', getattr(func, 'func_defaults'))
            setattr(func, '__code__', getattr(func, 'func_code'))
    funcs = sorted(funcs, key=lambda x:x.__name__)
    params = dict((f.__name__, list(zip_longest(f.__code__.co_varnames[:f.__code__.co_argcount][::-1], (f.__defaults__ or [])[::-1]))[::-1]) for f in funcs)
    def usage(applet):
        if applet == 'bb.py':
            print('Usage: {0} <applet> [arguments]\n\nExamples:\n{1}\n'.format(applet, '\n'.join('\t{0} {1} {2}'.format(applet, k, ' '.join('--{0} {1}'.format(x.replace('_', '-'), x.upper() if y is None else repr(y)) for (x, y) in v)) for k, v in params.items())))
        else:
            print('\nUsage:\n\t{0} {1}'.format(applet, ' '.join('--{0} {1}'.format(x.replace('_', '-'), x.upper() if y is None else repr(y)) for (x, y) in params[applet])))
    if '-h' in sys.argv or '--help' in sys.argv or (applet == 'bb.py' and not sys.argv[1:]):
        return usage(applet)
    if applet == 'bb.py':
        applet = sys.argv[1]
    for f in funcs:
        if f.__name__ == applet:
            break
    else:
        return usage()
    options = [x.replace('_','-')+'=' for x in f.__code__.co_varnames[:f.__code__.co_argcount]]
    kwargs, _ =  getopt.gnu_getopt(sys.argv[1:], '', options)
    kwargs = dict((k[2:].replace('-', '_'),v) for k, v in kwargs)
    logging.debug('main %s(%s)', f.__name__, kwargs)
    try:
        result = f(**kwargs)
    except TypeError as e:
        patterns = [r'missing \d+ .* argument', r'takes (\w+ )+\d+ argument']
        if any(re.search(x, str(e)) for x in patterns):
            return usage(applet)
        raise
    if type(result) == type(b''):
        result = result.decode().strip()
    if result:
        print(result)


if __name__ == '__main__':
    __main()

