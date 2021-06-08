<h1 align="center">
  <img src="https://blitline-web.s3.amazonaws.com/logos/allq-logo.svg" width="224px"/><br/>
  AllQueue Task Queue
</h1>
<p align="center">AllQueue is a modern job queue platform which incorporates many of the best features from other popular queues into a single full featured system.</p>


## ❓ Why AllQueue

There seems to be no queue platform that provides *all* the required functionality for modern apps in one spot. Many lack simple features like prioritization, or automatic DLQs, or throttling. AllQueue is an attempt to bring all these features into a single platform


Here is a list of features that AllQueue has:
- Simple deployment/configuration
- Delayed Jobs
- Independent named queues
- Prioritization within a queue (no need for different queues for 'priorty' jobs)
- Best attempt fair queuing
- Dead Letter queue
- Synchronous workflows (Jobs that depend on other jobs completing)
- Throttling queues
- In memory/disk based persistance
- Federated sharding for scalability
- Does not require ongoing maintenance of internal storage or sub-applications
- High Speed



## ⚡️ Quick start

Docker has 2 components. An AllqClient and the AllqServer. Your app talks to the client, and the client talks to the server (fully encrypted), no TLS to setup or maintain.



### 🐳 Requires Docker

Client

```bash
sudo docker run --rm=true blitline/allq:client
```

Server

```bash
sudo docker run --rm=true blitline/allq:server
```


## ⚠️ License

`Create Go App CLI` is free and open-source software licensed under the [Apache 2.0 License](https://github.com/create-go-app/cli/blob/master/LICENSE). Official [logo](https://github.com/create-go-app/cli/wiki/Logo) was created by [Vic Shóstak](https://shostak.dev/) and distributed under [Creative Commons](https://creativecommons.org/licenses/by-sa/4.0/) license (CC BY-SA 4.0 International).



echo '{"action" : "stats", "params" : {}}' | socat - tcp4-connect:localhost:7766

https://allqueue.gitbook.io/allq/




