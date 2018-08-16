# crayon-syntax-highlight

Code Highlight Service base on `crayon-syntax-highlight` by dockerize.

## Usage

```
# clone souce code
git clone https://github.com/soulteary/crayon-syntax-highlight.git

cd crayon-syntax-highlight

# start service
docker-compose up -d

# webview
http://127.0.0.1:1234/

# api
curl -x POST --data '[crayon lang="js"]\nvar a = 1;\nconsole.log(a);\n[/crayon]' http://127.0.0.1:1234/?api 
```
