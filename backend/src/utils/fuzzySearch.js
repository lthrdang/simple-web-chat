/**
 * Fuzzy search utility for approximate matching
 */

/**
 * Calculate the Levenshtein distance between two strings
 * Used to determine how similar two strings are
 * 
 * @param {string} s1 - First string
 * @param {string} s2 - Second string
 * @returns {number} - Distance value (lower means more similar)
 */
function levenshteinDistance(s1, s2) {
  // Convert strings to lowercase for case-insensitive comparison
  s1 = s1.toLowerCase();
  s2 = s2.toLowerCase();
  
  const m = s1.length;
  const n = s2.length;
  
  // Create a matrix of size (m+1) x (n+1)
  const dp = Array(m + 1).fill().map(() => Array(n + 1).fill(0));
  
  // Initialize first row and column
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      if (s1[i - 1] === s2[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 + Math.min(
          dp[i - 1][j],     // deletion
          dp[i][j - 1],     // insertion
          dp[i - 1][j - 1]  // substitution
        );
      }
    }
  }
  
  return dp[m][n];
}

/**
 * Check if a target string approximately matches a query string
 * 
 * @param {string} target - The string to check against
 * @param {string} query - The search query
 * @param {number} threshold - Maximum allowable distance (lower is stricter)
 * @returns {boolean} - True if strings approximately match
 */
function isApproximateMatch(target, query, threshold = 2) {
  if (!target || !query) return false;
  
  // Quick exact match check for efficiency
  if (target.toLowerCase().includes(query.toLowerCase())) return true;
  
  // For very short queries, use stricter matching
  if (query.length <= 2) {
    return target.toLowerCase().includes(query.toLowerCase());
  }
  
  // For longer queries, calculate Levenshtein distance
  const distance = levenshteinDistance(target, query);
  
  // Adaptive threshold based on query length
  const adaptiveThreshold = Math.min(threshold, Math.ceil(query.length / 3));
  
  return distance <= adaptiveThreshold;
}

/**
 * Filter an array of objects using fuzzy search
 * 
 * @param {Array} items - Array of objects to search through
 * @param {string} query - The search query
 * @param {Array} fields - Fields to search in each object
 * @param {number} threshold - Maximum allowable distance
 * @returns {Array} - Filtered and ranked results
 */
function fuzzySearch(items, query, fields, threshold = 2) {
  if (!query || !query.trim()) return items;
  
  const results = [];
  
  for (const item of items) {
    let matched = false;
    let bestScore = Number.MAX_SAFE_INTEGER;
    
    for (const field of fields) {
      if (!item[field]) continue;
      
      const fieldValue = String(item[field]);
      
      if (isApproximateMatch(fieldValue, query, threshold)) {
        matched = true;
        const score = levenshteinDistance(fieldValue, query);
        if (score < bestScore) bestScore = score;
      }
    }
    
    if (matched) {
      results.push({
        item,
        score: bestScore
      });
    }
  }
  
  // Sort by score (lower is better)
  return results
    .sort((a, b) => a.score - b.score)
    .map(result => result.item);
}

module.exports = {
  levenshteinDistance,
  isApproximateMatch,
  fuzzySearch
}; 