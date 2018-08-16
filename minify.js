#!/usr/bin/env node

'use strict';

const {readFileSync, writeFileSync, readdirSync, statSync} = require('fs');
const {join, relative} = require('path');

const {blackList, charset, errorReport} = require('./config.json');

/**
 * 扫描指定目录的文件
 * @param dirPath     目录位置
 * @param ext         文件类型（可选）
 * @returns {Array}   带目录结构的数组
 */
function getAllFiles(dirPath, ext) {

  function scanDir(dirPath, ext) {
    const result = readdirSync(dirPath);
    if (!result.length) return [];
    return result.filter(name => !(blackList || []).includes(name)).map((dirName) => {
      const filePath = join(dirPath, dirName);
      if (statSync(filePath).isDirectory()) {
        return scanDir(join(dirPath, dirName), ext);
      } else {
        if (!ext) return filePath;
        if (filePath.lastIndexOf(ext) === filePath.indexOf(ext) && filePath.indexOf(ext) > -1) {
          return filePath;
        }
        return '';
      }
    });
  }

  function flatten(arr) {
    return arr.reduce(function(flat, toFlatten) {
      return flat.concat(Array.isArray(toFlatten) ? flatten(toFlatten) : toFlatten);
    }, []);
  }

  return flatten(scanDir(dirPath, ext)).filter(file => file);
}

module.exports = function(sourceDirPath) {
  console.log(`开始处理: ${sourceDirPath}`);

  const sourceDir = relative('.', sourceDirPath);
  const allMarkdownFiles = getAllFiles(sourceDir, '.md');

  let contentHasError = [];
  let contentHasMore = [];
  let contentHasErrMore = [];

  allMarkdownFiles.forEach((file) => {
    const content = readFileSync(file, charset);

    // 检测是否存在代码高亮转换出错的文章
    if (content.indexOf('{{<crayonCode>}}') > -1) contentHasError.push(file);
    // 检测源文件是否包含截断标签
    if (content.indexOf('<!-- more -->') > -1) contentHasMore.push(file);

    // 统计标记错误的文章
    if (content.indexOf('<!-- More -->') > -1) contentHasErrMore.push(file);
    if (content.indexOf('<!-- -->') > -1) contentHasErrMore.push(file);
  });

  // trim expect tag
  contentHasMore.forEach((file) => {
    const contentTrimmed = readFileSync(file, charset).replace(/<!-- more -->\n/g, '');
    writeFileSync(file, contentTrimmed);
  });

  if (contentHasError.length) {
    console.log(`[高亮存在错误] ${contentHasError.length}`);
    writeFileSync(errorReport, JSON.stringify(contentHasError.reduce((prev, item) => {
      const cachePath = join('./cache', item.replace(/\.\.\//g, '')).replace(/^\//g, '');
      prev[cachePath] = true;
      return prev;
    }, {})));
    process.exit(1);
  } else {
    writeFileSync(errorReport, '{}');
  }

  if (contentHasErrMore.length) {
    console.log(`[摘要标记错误] ${contentHasErrMore.length}`);
    console.log(contentHasErrMore);
  }

  // trim space without code containers
  const allHtmlFiles = getAllFiles(sourceDir, '.html');
  const trimTags = (s) => s.replace(/>\s+</gm, '><').replace(/>(\s+\n|\r)/g, '>');
  allHtmlFiles.forEach((file) => {
    let content = readFileSync(file, charset).replace(/^\s+/, '');
    const snippet = content.match(/<div\s+id="crayon-[\s\S]+?\<\/td\><\/tr><\/table><\/div><\/div>/g);
    if (snippet) {
      for (let i = 0, j = snippet.length; i < j; i++) {
        content = content.replace(snippet[i], `<codeSnappet${i}/>`);
      }
      content = trimTags(content);
      for (let i = 0, j = snippet.length; i < j; i++) {
        content = content.replace(`<codeSnappet${i}/>`, snippet[i]);
      }
      writeFileSync(file, content);
    } else {
      content = trimTags(content);
      writeFileSync(file, content);
    }
  });

};
