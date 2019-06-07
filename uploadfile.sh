#!/bin/bash


#upload file in parts in (5 gigs each) the form of filename-partnumber

#if wrong arguments are provided then description of the script is returned to the user
if [ "$#" -lt 2 ]
then
    echo "usage: this script takes in two argument <fileName> and <splitSizeByByte>."
    echo "It will upload fileName in parts (split into smaller files based on specified byte size) to AWS s3."
    echo "It allows user to create a new bucket or pick the desired bucket from the provided list"
else
    arr=$(aws s3 ls) #gets the existing buckets from the aws s3 buckets list
    #initializing variables
    declare -a name
    index=0
    count=0
    pickNumb=0
    nameIndex=2
    bucketName="nb"

    #iterates through the string and stores the names of the buckets to a new array
    for word in $arr; do
        if [ $index -eq $nameIndex ]; then
            name[$count]=${word}
            ((nameIndex+=3))
            printf '%d. %s\n' "$(($count+1))" "${name[$count]}"
            ((count++))
            #echo "name is ${$name[count]}"
        fi
        ((index+=1))
    done

    #getting user input to either choose an existing bucket or create a new one
    read -p "Pick a bucket from the option or enter -1 to create a new bucket: " pickNumb

    #if statements handle the cases of either creating a new bucket or using any existing one
    if [ $pickNumb -eq -1 ]; then
        read -p "Please enter the new bucket's name: " bucketName
        aws s3api create-bucket --bucket $bucketName --region us-east-1
        echo "new bucket is created"
    else
        bucketName=${name[$(($pickNumb-1))]}
        echo "$bucketName"
    fi


    aws configure


    #getting arguments from command line
    sourceFile=$1
    splitSize=$2
    echo "target file: $sourceFile"

    #splits the original large file into many small files based on the users desired file size
    split -d -C $splitSize $sourceFile message
    echo "successfully split up the files"

    #uploads all the splitted files in the local directory into the defined aws bucket
    for filename in message*; do

            aws s3 cp $filename s3://$bucketName
            echo "uploaded $filename to s3://$bucketName"

            rm $filename
            echo "deleted this file in the local repository"
    done
fi
