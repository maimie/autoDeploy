#!/bin/sh

#引数チェック ------------------------------------------------------------
if [ ! $1 ]; then
    echo "引数がありません"
    exit 1
fi

#第二引数
if [ ! $2 ]; then
    echo "パスワード用数値が入力されていません"
    exit 1
fi

#ディレクトリチェック
if [ -d /home/$1 ]; then
    echo "既に作成済みです"
    exit 1
fi
# --------------------------------------------------------------------

#秘密鍵・公開鍵を追加 --------------------------------------------------
function inputConnectionKey() {
    #比較用変数を初期化
    result=false
    authorized_keys=""

    #公開鍵を取得
    Public_Key=`cat /home/shell/public_key`
    #秘密鍵を取得
    Private_Key=`cat /home/shell/private_key`

    #$1フォルダの存在チェック
    if [ ! -d /home/$1 ]; then
        #存在していない場合
        #パーミッション755でフォルダを作成
        mkdir -m 755 /home/$1
    fi

    #.sshフォルダを作成
    if [ ! -d /home/$1/.ssh ]; then
        #存在していない場合
        #パーミッション700でフォルダを作成
        mkdir -m 700 /home/$1/.ssh
    fi

    #authorized_keysファイルの存在チェック
    if [ -e /home/$1/.ssh/authorized_keys ]; then
        #存在する場合
        #設定済みの公開鍵を取得
        authorized_keys=`cat /home/$1/.ssh/authorized_keys`
        #公開鍵が既に設定済みチェック
        if grep "$Public_Key" "/home/$1/.ssh/authorized_keys" >/dev/null; then
            result=true
        fi
    else
        #存在していない場合
        touch /home/$1/.ssh/authorized_keys
    fi

    #公開鍵が設定されていない場合
    if ! $result; then
        #文字列の長さチェック
        if [[ -z $authorized_keys ]]; then
            ##長さがゼロの場合
            echo "$Public_Key" > /home/$1/.ssh/authorized_keys
        else
            ##長さがゼロより大きい場合
            echo "$Public_Key" >> /home/$1/.ssh/authorized_keys
        fi
    fi

    #authorized_keysファイルのパーミッションを変更
    chmod 600 /home/$1/.ssh/authorized_keys

    #repファイルの存在チェック
    if [ ! -e /home/$1/.ssh/rep ]; then
        #存在していない場合
        #ファイルを作成
        touch /home/$1/.ssh/rep
        #秘密鍵を追加
        echo "$Private_Key" > /home/$1/.ssh/rep
    fi

    #repファイルのパーミッションを変更
    chmod 400 /home/$1/.ssh/rep

    #所有者・所属グループを変更
    chown -R $1:$1 /home/$1/.ssh/
}

#接続テスト
function connectionCheck() {
    
    #定数
    ConnectMessage="connect_ok"

    #接続テスト
    result=`ssh -i /home/$1/.ssh/rep $1@$3 -p$4 "echo $ConnectMessage"`
    
    if [ "$result" != "$ConnectMessage" ]; then
        echo "error"
        return 1
    fi

    #異常なし
    echo ""
    return 0
}
# --------------------------------------------------------------------

#定数
ProjectName=$1
ReposName="repos"
ConnectMessage="connect_ok"
Password=$2
Host=$3
Port=$4


#ユーザーを作成 ---------------------------------------------------
adduser $ProjectName
#$ProjectNameフォルダのパーミッションを変更
chmod 755 /home/$ProjectName

#.bash_profileファイルを実行
source /home/$ProjectName/.bash_profile
# --------------------------------------------------------------------


#秘密鍵・公開鍵を追加 ------------------------------------------------
#プロジェクト
inputConnectionKey $ProjectName

#リモートrepos
inputConnectionKey $ReposName

#接続テスト プロジェクト→リモート
isConnection=`connectionCheck $ProjectName $ReposName $Host $Port`
if [ "$isConnection" != "" ]; then
    echo "「$ProjectName → $ReposName」接続失敗"
    exit 1
fi

#接続テスト リモート→プロジェクト
isConnection=`connectionCheck $ReposName $ProjectName $Host $Port`
if [ "$isConnection" != "" ]; then
    echo "「$ReposName → $ProjectName」接続失敗"
    exit 1
fi

# --------------------------------------------------------------------


#プロジェクト設定を作成 ---------------------------------------------------

#configファイルを作成
touch /home/$ProjectName/.ssh/config

#鍵認証接続の設定文字列を追加
echo "Host remoteRepos" > /home/$ProjectName/.ssh/config
echo "HostName $3" >> /home/$ProjectName/.ssh/config
echo "User $ReposName" >> /home/$ProjectName/.ssh/config
echo "Port $4" >> /home/$ProjectName/.ssh/config
echo "IdentityFile /home/$ProjectName/.ssh/rep" >> /home/$ProjectName/.ssh/config
echo "StrictHostKeyChecking no"  >> /home/$ProjectName/.ssh/config
#↑初回接続時にYES/NOが聞かれるメッセージを表示しない設定。最後に行っているgit pushで上記の設定がないとエラーになる

#configファイルのパーミッションを変更
chmod 600 /home/$ProjectName/.ssh/config

#所有者・所属グループを変更
chown $ProjectName:$ProjectName /home/$ProjectName/.ssh/config

#オプション定数
#-o StrictHostKeyChecking=no：初回接続時に表示される確認メッセージを表示させない設定
#UserKnownHostsFile=/dev/null：known_hostsファイルに追記しない設定
#LogLevel=QUIET：接続ログを表示しない設定
Connect_Option="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=QUIET"
#接続テスト
isRemoteRepos=`ssh $Connect_Option -i /home/$ReposName/.ssh/rep $ProjectName@$3 -p$4 "ssh $Connect_Option -t -t remoteRepos "echo $ConnectMessage""`
#接続判定
if echo "$isRemoteRepos" | grep "$ConnectMessage" >/dev/null; then
    :
else
    echo "「remoteRepos」での接続失敗"
    exit 1
fi

#$ProjectNameフォルダに移動
cd /home/$ProjectName

#リポジトリを作成
git init
git config user.name $ProjectName
git config user.email "system@hoge.jp"
git config remote.origin.url "ssh://remoteRepos/home/$ReposName/$ProjectName/repos.git"
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git config branch.master.remote "origin"
git config branch.master.merge "refs/heads/master"
git config branch.dev_master.remote "origin"
git config branch.dev_master.merge "refs/heads/dev_master"

#所有者・所属グループを変更
chown -R $ProjectName:$ProjectName /home/$ProjectName

# --------------------------------------------------------------------


#リモート設定を作成 ---------------------------------------------------

#所有者・所属グループを変更
chown $ReposName:$ReposName /home/$ReposName

#所有者・所属グループを変更
chown -R $ReposName:$ReposName /home/$ReposName/.ssh

#プロジェクトのディレクトリを作成
mkdir -p /home/$ReposName/$ProjectName/repos.git

#repos.gitフォルダ内に移動
cd /home/$ReposName/$ProjectName/repos.git

#リモートリポジトリを作成
git --bare init --shared

#hooksフォルダ内に移動
cd hooks

#post-receiveファイルを作成
touch post-receive

#autoDeployコードを追加
echo "ssh -i /home/$ReposName/.ssh/rep $ProjectName@$3 -p$4 \"cd ~;git pull\"" > post-receive

#実行権限を付ける
chmod a+x post-receive

#所有者・所属グループを変更
chown -R $ReposName:$ReposName /home/$ReposName/$ProjectName

# --------------------------------------------------------------


#ヴァーチャルホストの作成 --------------------------------------------

#ファイル確認用変数
isExists=true

#定数
VirtualHostFile=/etc/httpd/conf/httpd.conf

#virtualhost.confファイルの存在チェック
if [ ! -f $VirtualHostFile ]; then
    #ファイルが無い場合
    #ファイルを作成
    touch $VirtualHostFile
    #フラグを設定
    $isExists=false
fi

#virtualhost.confファイルのパーミッションを変更
chmod 644 $VirtualHostFile

#ファイルの中身を取得
xml=`cat $VirtualHostFile`
#既に設定済みチェック
if [ ! $(echo "$xml" | grep -sq "$ProjectName") ]; then
    #設定されていない場合

    #設定xmlを追加
    #既にファイルが作成されていた場合
    if [ $isExists ]; then
        echo "" >> $VirtualHostFile
        echo "#$ProjectName" >> $VirtualHostFile
    else
        echo "#$ProjectName" > $VirtualHostFile
    fi
    echo "<VirtualHost *:80>" >> $VirtualHostFile
    echo "    DocumentRoot /home/$ProjectName/public" >> $VirtualHostFile
    echo "    ServerName $ProjectName.mysite.jp" >> $VirtualHostFile
    echo "    ErrorLog /home/$ProjectName/logs/$ProjectName.mysite.jp-error_log" >> $VirtualHostFile
    echo "    CustomLog /home/$ProjectName/logs/$ProjectName.mysite.jp-access_log combined" >> $VirtualHostFile
    echo "</VirtualHost>" >> $VirtualHostFile    
fi

# --------------------------------------------------------------


# htpasswdファイルを作成 ------------------------------------------------------

htpasswd -c -b /home/$ProjectName/.htpasswd $ProjectName $ProjectName$Password

# -----------------------------------------------------------------------------


# htaccessファイル内にプロジェクト名を追加 ---------------------------------------------------------

#パスを作成
htaccessPath="/home/$ProjectName/public/.htaccess"

#ファイルがあるか判定
if [ -f $htaccessPath ]; then
    grep -l "PROJECTNAME" $htaccessPath | xargs sed -i -e "s/PROJECTNAME/$ProjectName/g"
fi

# --------------------------------------------------------------------------------------------



#.gitignoreファイルを作成 -----------------------------------------------------------------------

#パスを作成
gitignore_Path=/home/$ProjectName/.gitignore

#ファイルがあるか判定
if [ ! -f $gitignore_Path ]; then
    touch $gitignore_Path
fi

#書き込み内容を取得
gitignore_content=$(cat $gitignore_Path)

#書き込み内容チェック
if [ -z $gitignore_content ]; then
    #書き込み内容が無い場合
    echo ".bash_history" > $gitignore_Path
else
    echo ".bash_history" >> $gitignore_Path
fi
echo ".bash_logout" >> $gitignore_Path
echo ".bash_profile" >> $gitignore_Path
echo ".bashrc" >> $gitignore_Path
echo ".htpasswd" >> $gitignore_Path
echo ".cache" >> $gitignore_Path
echo ".viminfo" >> $gitignore_Path
echo ".ssh" >> $gitignore_Path
echo "logs" >> $gitignore_Path

#パーミッションを設定
chmod 664 $gitignore_Path


#所有者・所属グループを変更
chown -R $ProjectName:$ProjectName $gitignore_Path
# --------------------------------------------------------------------------------------------


#再起動
service httpd graceful

# ブランチの作成 -------------------------------------------------------------

echo `ssh -i /home/$ReposName/.ssh/rep $ProjectName@$3 -p$4 "cd ~ ; git add .; git commit -m \"First Commit.\" ; git checkout -b dev_master; git push origin dev_master;"`

# -------------------------------------------------------------------------------
