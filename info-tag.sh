echo "=== Local Tags ==="
git tag

echo ""
echo "=== Tags with Commits ==="
git show-ref --tags

echo ""
echo "=== Commit Log with Tags ==="
git log --oneline --decorate --tags -n 10

echo ""
echo "=== Remote Tags ==="
git ls-remote --tags origin
