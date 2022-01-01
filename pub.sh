git checkout master
git pull origin master
git push origin --delete gh-pages
git branch -D gh-pages
git checkout --orphan gh-pages
gitbook install
gitbook build
rm -rf `ls | grep -v "_book"`
cd _book
if  [ $? == 0 ]
then
mv * ./..
cd ./..
rm -rf _book
git add .
git commit -m "auto build"
git push origin gh-pages
git checkout master
echo "build succeeded"
else
echo "build failed"
fi
