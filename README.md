
# ble_test

# **How to add tag and remove :** 

- git tag -a v1.0.0 -m "First stable release"
- git push origin v1.0.0
#### **Later if you want to remove :**
- git tag -d v1.0.0
- git push origin --delete v1.0.0
***=== Local Tags ===***
git tag
***=== Tags with Commits ===***
git show-ref --tags
***=== Commit Log with Tags ===***
git log --oneline --decorate --tags -n 10
***=== Remote Tags ===***
git ls-remote --tags origin
#### ***🔹 List semua tag***
git tag
#### ***🔹 List tag tertentu (contoh: mulai dengan v1.)***
git tag -l "v1.*"
#### ***🔹 Lihat detail tag tertentu***
git show v1.0.0
#### ***🔹 Lihat commit beserta tag-nya***
git log --oneline --decorate --tags
#### ***🔹 Lihat semua tag dengan commit hash***
git show-ref --tags
#### ***🔹 Lihat semua tag yang ada di remote***
git ls-remote --tags origin

