#!/bin/bash

svn stat | grep '^?' | while read F ; do 
	echo "deleting $F.."
	rm -rf $F
done
