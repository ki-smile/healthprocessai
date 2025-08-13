#!/usr/bin/env python3
"""
Generate JavaScript data file with actual report contents
"""

import os
import json
import glob

def read_report(filepath):
    """Read a markdown report file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return f"# Error Loading Report\n\nCould not read the report from {filepath}"

def main():
    base_path = "../legacy_original/R/Reports"
    
    # Case mappings
    cases = {
        "case1": "Case I - Infection",
        "case2": "Case II - Organ Damage", 
        "case3": "Case III - Glomerular Filtration Rate",
        "case4": "Case IV - Kidney Disease Progression"
    }
    
    # Model mappings (extract model name from filename)
    model_map = {
        "anthropic": "anthropic",
        "deepseek": "deepseek",
        "google": "google",
        "openai": "openai",
        "x-ai": "xai"
    }
    
    # Build the report data structure
    report_data = {}
    
    for case_id, case_name in cases.items():
        report_data[case_id] = {}
        case_path = os.path.join(base_path, case_name)
        
        if os.path.exists(case_path):
            # Find all markdown files in this case directory
            md_files = glob.glob(os.path.join(case_path, "*.md"))
            
            for md_file in md_files:
                filename = os.path.basename(md_file)
                
                # Extract model name from filename
                for model_key in model_map.keys():
                    if model_key in filename.lower():
                        model_id = model_map[model_key]
                        content = read_report(md_file)
                        report_data[case_id][model_id] = {
                            "content": content,
                            "filename": filename
                        }
                        print(f"Loaded {case_id}/{model_id}: {filename}")
                        break
    
    # Generate JavaScript file
    js_content = f"""// Auto-generated report data from actual markdown files
// Generated on: {__import__('datetime').datetime.now().isoformat()}

const actualReportData = {json.dumps(report_data, indent=2)};

// Override the reportData variable if it exists
if (typeof reportData !== 'undefined') {{
    Object.assign(reportData, actualReportData);
}} else {{
    var reportData = actualReportData;
}}

console.log('Loaded actual report data for', Object.keys(actualReportData).length, 'cases');
"""
    
    # Write to file
    output_file = "actual_reports.js"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(js_content)
    
    print(f"\nGenerated {output_file} with {len(report_data)} cases")
    
    # Summary
    for case_id, models in report_data.items():
        print(f"  {case_id}: {len(models)} models")

if __name__ == "__main__":
    main()