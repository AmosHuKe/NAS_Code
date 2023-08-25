#!/bin/sh

# 获取 Github 个人的所有仓库（默认分支），进行 clone 和同步拉取最新操作。
# 环境：Git，需要预先配置 Git，以便私有仓库的操作。

# ------ BEGIN 配置 ------

  # Github Accesstoken
  # 获取 repo 的范围需要自行在权限中控制
  # 比如：获取所有 repo（包括私有），需要勾选上 Repository permissions -> Contents 可读
  accesstoken=""

  # repo 文件夹
  directoryRepo="github"

  # 临时文件夹
  directoryTemp=".temp"

  # 临时 git_clone_url 文件名
  gitCloneUrl="git_clone_url.txt"

# ------ END 配置 ------

# ------ BEGIN 获取所有 repo 链接 ------
echo "------ BEGIN 获取所有 repo 链接 ------"

  # 创建临时文件夹并进入
  mkdir -p $directoryTemp
  cd $directoryTemp

  # 清空文件
  > $gitCloneUrl

  # 获取个人每页的 repo
  repo="-" # 临时单页数据
  repos="" # 总数据
  page=1 # 页数

  # 循环每页
  while [ -n "$repo" ]
  do
    echo "------ BEGIN 正在获取第 $page 页 repo ------"

    repo=""

    # 获取 clone_url
    repo=$( \
      curl -L \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $accesstoken" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/user/repos?per_page=50&page=$page&sort=updated" \
      | grep -w "clone_url" \
    )

    if [ -n "$repo" ]
    then
      # 清理链接
      repo=$(echo "$repo" | grep -P -o "https://github.com/(.)*.git")
      repo=$(echo "$repo" | awk '{gsub(/^\s+|\s+$/, "");print}')

      repos+="$repo\r\n"
      let page++
    fi

    echo "------ END 正在获取第 $page 页 repo ------"
    echo ""
  done

  # 写入文件
  echo -e "$repos" > $gitCloneUrl

echo "------ END 获取所有 repo 链接 ------"
echo ""
# ------ END 获取所有 repo 链接 ------

# ------ BEGIN 操作 Git clone ------
echo "------ BEGIN 操作 Git clone ------"

  # 创建 repo 文件夹并进入
  cd ..
  mkdir -p $directoryRepo
  cd $directoryRepo

  # 处理每行数据
  while read repoLine
  do
    if [ -n "$repoLine" ]
    then
      echo "------ BEGIN 操作 Git clone $repoLine ------"

      git clone $repoLine

      echo "------ END 操作 Git clone $repoLine ------"
      echo ""
    fi
  done < "../$directoryTemp/$gitCloneUrl"

echo "------ END 操作 Git clone ------"
echo ""
# ------ END 操作 Git clone ------

# ------ BEGIN 遍历所有 Repo 并同步拉取 ------
echo "------ BEGIN 遍历所有 Repo 并同步拉取 ------"

repoFiles=`ls`
for repoFile in $repoFiles
do
  repofilename=`basename $repoFile`

  echo "------ BEGIN 同步拉取 $repofilename ------"
  
  cd $repofilename

  # 判断是否空文件夹，代表 clone 未完成，需要删除文件夹。
  thisRepoFiles=`ls`
  if [ -z "$thisRepoFiles" ]
  then
    cd ..
    rm -rf $repofilename
  else
    git pull
    cd ..
  fi

  echo "------ END 同步拉取 $repofilename ------"
  echo ""
done

echo "------ END 遍历所有 Repo 并同步拉取 ------"
echo ""
# ------ END 遍历所有 Repo 并同步拉取 ------
