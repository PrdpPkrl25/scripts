import json
import requests
from prettytable import PrettyTable

webhookUrl= "https://example.com/hooks/i7f33xci6bbg886p4yse4oi4xy"

def get_domains():
    res= requests.get(
        "https://api.eu.mailgun.net/v3/domains",
        auth=("api", "key-e06bad32a65d1b1a4537ef44fd6078c0"),
        params={"skip": 0,
                "state":"active"})
    return res

def get_stats(domains):
    stats={}
    for domain in domains:
        stat=requests.get(
            f"https://api.eu.mailgun.net/v3/{domain}/stats/total",
            auth=("api", "key-e06bad32a65d1b1a4537ef44fd6078c0"),
            params={"event": ["delivered", "failed"],
                    "duration": "1d"})
        stat=json.loads(stat.content)['stats']
        stats[domain]=stat
    return stats

def post_request(webhookUrl,data):
    headers = {
        "Content-Type": "application/json",
    }
    payload={"text":data}
    response=requests.post(webhookUrl,json=payload,headers=headers,)
    print(response)

if __name__ == "__main__":
    res=get_domains()
    res=json.loads(res.content)['items']
    domains=[]
    for a in range(len(res)):
        domains.append(res[a]['name'])  
    stats=get_stats(domains)
    t=PrettyTable(['Date','Domain','Total Delivered','Total Temporary Failed','Total Permanent Failed'])
    for domain in domains:
        t.add_row([stats[domain][0]['time'],domain,stats[domain][0]['delivered']['total'],stats[domain][0]['failed']['temporary']['total'],stats[domain][0]['failed']['permanent']['total']])
    with open(f'result.txt', 'w') as f:
        f.write(t.get_string())
        f.close()
    with open('result.txt', 'r') as file:
        data = file.read()
    post_request(webhookUrl,data)
