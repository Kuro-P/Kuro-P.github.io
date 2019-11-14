# hexo build (master)
hexo g
sudo hexo deploy

# git commit (develop)
git status
read -t 30 -p "Confirm summit changes(Y/N)?" confirm
read -t 30 -p "Please enter commit message:" message
if [ $confirm == "Y" ]
then 
    echo "Start commiting files to github"
    git add .
    git commit -m "$message"
    git push
else
    echo "Develop files reserve abort."    
fi 
echo "Done."   