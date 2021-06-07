rm -rf .deploy_git
hexo clean
hexo g
hexo d
rm -rf .deploy_git
git add -A
git commit -m "fix bug"
#git commit -m "fix bugs"
git push origin master
rm -rf public
#rm -rf .deploy_git
#hexo clean && hexo deploy

