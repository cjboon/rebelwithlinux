#!/bin/bash

# Fast dark mode cleanup - remove buttons from all pages except homepage

# Remove themeToggle elements from all HTML files except index.html
find . -name "*.html" -not -name "index.html" -exec sed -i '/<themeToggle/,/</label>/d' {} \;

# Remove JavaScript dark mode code from all HTML files except index.html
find . -name "*.html" -not -name "index.html" -exec sed -i '/toggleTheme/d' {} \;
find . -name "*.html" -not -name "index.html" -exec sed -i '/localStorage/d' {} \;
find . -name "*.html" -not -name "index.html" -exec sed -i '/document.getElementById.*themeToggle/d' {} \;

# Remove any remaining theme-related JavaScript
find . -name "*.html" -not -name "index.html" -exec sed -i '/'toggleTheme'/d' {} \;
find . -name "*.html" -not -name "index.html" -exec sed -i '/'themeToggle'/d' {} \;

# Remove any empty lines left by deletions
find . -name "*.html" -not -name "index.html" -exec sed -i '/^\s*$/d' {} \;

# Remove any orphaned <label> tags
find . -name "*.html" -not -name "index.html" -exec sed -i '/<label[^/]*>/Id' {} \;

# Fix navigation spacing
find . -name "*.html" -not -name "index.html" -exec sed -i 's/\s\s/\s/g' {} \;

# Remove any remaining theme-related CSS from individual pages
find . -name "*.html" -not -name "index.html" -exec sed -i '/--ivory:/Id' {} \;
find . -name "*.html" -not -name "index.html" -exec sed -i '/--white:/Id' {} \;
find . -name "*.html" -not -name "index.html" -exec sed -i '/--black:/Id' {} \;
find . -name "*.html" -not -name "index.html" -exec sed -i '/--charcoal:/Id' {} \;

# Remove any style blocks with theme-related CSS
find . -name "*.html" -not -name "index.html" -exec sed -i '/<style/,/</style>/Id' {} \;

echo "Fast cleanup complete! Dark mode buttons removed from all pages except homepage."