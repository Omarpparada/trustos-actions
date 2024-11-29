import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

const ignoreList = ['.git', 'node_modules'];

function shouldIgnore(itemPath) {
    const normalizedPath = path.normalize(itemPath);
    return ignoreList.some(ignoredItem => 
        normalizedPath === ignoredItem ||
        normalizedPath.startsWith(ignoredItem + path.sep) ||
        normalizedPath.includes(path.sep + ignoredItem + path.sep)
    );
}

export function generateReleaseHash(directoryPath) {
    const hash = crypto.createHash('sha256');
    const hashedFiles = [];
    processDirectory(directoryPath, hash, '', hashedFiles);
    return {
        hash: hash.digest('hex'),
        hashedFiles: hashedFiles
    };
}

function processDirectory(dirPath, hash, relativePath, hashedFiles) {
    const items = fs.readdirSync(dirPath).sort();

    items.forEach(item => {
        const fullPath = path.join(dirPath, item);
        const itemRelativePath = path.join(relativePath, item);

        if (shouldIgnore(itemRelativePath)) {
            console.log(`Ignorando: ${itemRelativePath}`);
            return;
        }

        const stats = fs.statSync(fullPath);

        if (stats.isDirectory()) {
            hash.update(`dir:${itemRelativePath}\n`);
            processDirectory(fullPath, hash, itemRelativePath, hashedFiles);
        } else if (stats.isFile()) {
            const content = fs.readFileSync(fullPath);
            hash.update(`file:${itemRelativePath}\n`);
            hash.update(content);
            hashedFiles.push(itemRelativePath);
        }
    });
}

// Uso
/* const directoryPath = process.argv[2] || '.';
const { hash: releaseHash, hashedFiles } = generateReleaseHash(directoryPath);
console.log(`Hash del release: ${releaseHash}`);
console.log(`Archivos hasheados (${hashedFiles.length}):`);
hashedFiles.forEach(file => console.log(` - ${file}`));
 */