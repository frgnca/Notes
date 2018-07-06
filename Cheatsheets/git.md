### Concept

1. Initialize local repo

2. Clone from remote repo to local repo

----------

3. Fetch from remote repo to remote branch

4. Merge from remote branch to local branch

5. Create new branch

6. Working Directory (add)> Staging area (commit)> Local Repository

7. Fetch from remote repo to remote branch again

8. Merge from remote branch to local branch again

9. Push

### Workflow

Initialize current folder as empty git repo

    git init

Check status

    git status

Add file to staging area

    git add _FILENAME_

Show difference after changing file

    git diff _FILENAME_

Commit changes from staging area to repository

    git commit -m "Write a short description of changes made in the present tense"

### Backtrack

Show list of all previous commits and their SHA hash

    git log

Show the HEAD commit

    git show HEAD

Restore file in working directory to match HEAD

    git checkout HEAD _FILENAME_

Restore file in staging area to match HEAD commit

    git reset HEAD _FILENAME_

Rewind HEAD to a previous commit using the first 7 characters of its SHA hash

    git reset _SHA_

### Branching

Show branches (current in green and with asterisk)

    git branch

Create new branch from current branch

    git branch _BRANCHNAME_

Change current branch

    git checkout _BRANCHNAME_

Merge a branch into the current branch

    git merge _BRANCHNAME_

Resolve merge conflict in file

* Select from "<<<<<<< HEAD" to “>>>>>>> _BRANCHNAME_”

* Replace with result of conflict

*     git add _FILENAME_

*     git commit -m "Resolve merge conflict"

Delete branch (does not work with current branch)

    git branch -d _BRANCHNAME_

### Teamwork

Clone a remote repo

    git clone _REMOTEREPO_ _LOCALREPO_

Show remote origin of a repo

    git remote -v

Fetch changes to current branch from remote repo into remote branch (origin/_BRANCHNAME_)

    git fetch

Merge changes from remote branch into current branch

    git merge origin/_BRANCHNAME_

Push local branch to remote repo

    git push origin _BRANCHNAME_
