// Dynamic report loader for LLM evaluation page
const reportPaths = {
    case1: {
        anthropic: '../legacy_original/R/Reports/Case I - Infection/Report_anthropic_sonnet-4.md',
        deepseek: '../legacy_original/R/Reports/Case I - Infection/Report_deepseek_deepseek-r1.md',
        google: '../legacy_original/R/Reports/Case I - Infection/Report_google_gemini-2_5-pro.md',
        openai: '../legacy_original/R/Reports/Case I - Infection/Report_openai_gpt-4_1.md',
        xai: '../legacy_original/R/Reports/Case I - Infection/Report_x-ai_grok-4.md'
    },
    case2: {
        anthropic: '../legacy_original/R/Reports/Case II - Organ Damage/Report_anthropic_sonnet-4.md',
        deepseek: '../legacy_original/R/Reports/Case II - Organ Damage/Report_deepseek_deepseek-r1.md',
        google: '../legacy_original/R/Reports/Case II - Organ Damage/Report_google_gemini-2_5-pro.md',
        openai: '../legacy_original/R/Reports/Case II - Organ Damage/Report_openai_gpt-4_1.md',
        xai: '../legacy_original/R/Reports/Case II - Organ Damage/Report_x-ai_grok-4.md'
    },
    case3: {
        anthropic: '../legacy_original/R/Reports/Case III - Glomerular Filtration Rate/Report_anthropic_sonnet-4.md',
        deepseek: '../legacy_original/R/Reports/Case III - Glomerular Filtration Rate/Report_deepseek_deepseek-r1.md',
        google: '../legacy_original/R/Reports/Case III - Glomerular Filtration Rate/Report_google_gemini-2_5-pro.md',
        openai: '../legacy_original/R/Reports/Case III - Glomerular Filtration Rate/Report_openai_gpt-4_1.md',
        xai: '../legacy_original/R/Reports/Case III - Glomerular Filtration Rate/Report_x-ai_grok-4.md'
    },
    case4: {
        anthropic: '../legacy_original/R/Reports/Case IV - Kidney Disease Progression/Report_anthropic_sonnet-4.md',
        deepseek: '../legacy_original/R/Reports/Case IV - Kidney Disease Progression/Report_deepseek_deepseek-r1.md',
        google: '../legacy_original/R/Reports/Case IV - Kidney Disease Progression/Report_google_gemini-2_5-pro.md',
        openai: '../legacy_original/R/Reports/Case IV - Kidney Disease Progression/Report_openai_gpt-4_1.md',
        xai: '../legacy_original/R/Reports/Case IV - Kidney Disease Progression/Report_x-ai_grok-4.md'
    }
};

// Function to load report from file
async function loadReportFromFile(caseId, model) {
    try {
        const path = reportPaths[caseId][model];
        const response = await fetch(path);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const markdown = await response.text();
        return markdown;
    } catch (error) {
        console.error('Error loading report:', error);
        // Fallback to embedded sample if file can't be loaded
        return `# Error Loading Report\n\nCould not load the report file from: ${reportPaths[caseId][model]}\n\nThis might be because:\n- The file doesn't exist at the specified path\n- CORS restrictions when loading local files\n- Network connectivity issues\n\nPlease ensure the report files are available in the legacy_original/R/Reports directory.`;
    }
}

// Override the loadReport function to use dynamic loading
async function loadReportDynamic() {
    const content = document.getElementById('reportContent');
    content.innerHTML = '<p style="text-align: center;">Loading report...</p>';
    
    try {
        const markdown = await loadReportFromFile(currentCase, currentModel);
        const htmlContent = marked.parse(markdown);
        content.innerHTML = htmlContent;
    } catch (error) {
        console.error('Error rendering report:', error);
        content.innerHTML = '<p>Error loading report. Please check the console for details.</p>';
    }
}

// Export for use in main page
window.loadReportFromFile = loadReportFromFile;
window.loadReportDynamic = loadReportDynamic;