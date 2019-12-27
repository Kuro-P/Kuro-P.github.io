#!/bin/bash
# git commit (develop)
git status
git diff
read -t 30 -p "Confirm summit changes(Y/N)?" confirm

if [ $(echo $confirm | tr '[A-Z]' '[a-z]')=="y" ]
then
    read -t 30 -p "Please enter commit message:" message
    echo "Start commiting files to github"
    git add .
    git commit -m "$message"
    git push

    CONFIG_URL="_config.yml"
    if [ -f ${CONFIG_URL} ]
        then
            echo "Start "
            sed -i "" "s/commit_message/$message/g" ${CONFIG_URL}
            # hexo build (master)
            hexo g
            sudo hexo deploy
            sed -i "" "s/$message/commit_message/g" ${CONFIG_URL}
    fi        

else
    echo "Develop files reserve abort."    
fi 
echo "Done."