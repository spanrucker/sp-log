./build.sh

git add *
git commit -am 'sync'
git push

rsync -rva -e 'ssh -p 22007' * fropac@185.181.117.72:log.simonpanrucker.com
