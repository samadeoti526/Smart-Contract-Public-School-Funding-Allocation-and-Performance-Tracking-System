# Smart Contract Public School Funding Allocation and Performance Tracking System

A comprehensive blockchain-based system for managing public school funding, performance tracking, and resource allocation using Clarity smart contracts.

## System Overview

This system consists of five interconnected smart contracts that work together to create a transparent, fair, and efficient public school funding and performance tracking system:

### 1. Student Funding Distribution Contract (`student-funding.clar`)
- Allocates funding based on student demographics and needs
- Supports weighted funding for special needs, low-income, and ESL students
- Tracks per-pupil funding amounts and distribution history
- Implements funding formulas based on student characteristics

### 2. Teacher Performance Evaluation Contract (`teacher-performance.clar`)
- Manages objective teacher performance assessments
- Tracks multiple evaluation criteria and scoring
- Maintains performance history and improvement tracking
- Supports performance-based incentives and professional development

### 3. School Resource Utilization Contract (`resource-tracking.clar`)
- Monitors school budget allocation and spending
- Tracks resource categories (instruction, administration, facilities, etc.)
- Provides transparency in resource utilization
- Implements spending approval and audit trails

### 4. Student Achievement Outcomes Contract (`student-outcomes.clar`)
- Records and tracks student academic performance
- Manages standardized test scores and progress metrics
- Calculates school-wide performance indicators
- Supports longitudinal student progress tracking

### 5. Parent Involvement Tracking Contract (`parent-involvement.clar`)
- Tracks parent participation in school activities
- Manages volunteer hours and engagement metrics
- Supports parent-teacher communication logging
- Implements incentive systems for parent involvement

## Key Features

### Transparency and Accountability
- All funding allocations and spending are recorded on-chain
- Performance metrics are publicly verifiable
- Audit trails for all major decisions and transactions

### Fair Distribution
- Evidence-based funding formulas
- Objective performance evaluation criteria
- Equitable resource allocation based on student needs

### Data-Driven Decisions
- Comprehensive performance tracking
- Historical data analysis capabilities
- Predictive insights for resource planning

### Stakeholder Engagement
- Parent involvement tracking and incentives
- Teacher performance recognition
- Student progress monitoring

## Contract Architecture

Each contract is designed to be:
- **Independent**: No cross-contract dependencies
- **Secure**: Proper access controls and validation
- **Scalable**: Efficient data structures and operations
- **Transparent**: Public read functions for accountability

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

3. Run tests:
   \`\`\`bash
   npm test
   \`\`\`

4. Deploy contracts:
   \`\`\`bash
   clarinet deploy
   \`\`\`

### Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for system workflows
- Edge case and error condition testing

Run the test suite:
\`\`\`bash
npm run test
\`\`\`

## Usage Examples

### Allocating Student Funding
\`\`\`clarity
;; Add a student with special needs weighting
(contract-call? .student-funding add-student
u12345
"John Doe"
u8
true   ;; special-needs
false  ;; esl-student
true)  ;; low-income
\`\`\`

### Recording Teacher Performance
\`\`\`clarity
;; Submit teacher evaluation
(contract-call? .teacher-performance submit-evaluation
"teacher-001"
u85  ;; classroom-management
u90  ;; student-engagement
u88  ;; curriculum-delivery
u92) ;; professional-development
\`\`\`

### Tracking Resource Spending
\`\`\`clarity
;; Record resource expenditure
(contract-call? .resource-tracking record-expenditure
"school-001"
"instruction"
u50000
"Textbooks and learning materials")
\`\`\`

## Data Models

### Student Record
- Student ID (unique identifier)
- Name and grade level
- Special needs indicators
- Funding weights and amounts

### Teacher Evaluation
- Teacher ID and evaluation period
- Multiple performance criteria scores
- Overall rating and improvement areas
- Professional development tracking

### Resource Allocation
- School ID and budget categories
- Expenditure amounts and descriptions
- Approval status and audit trails
- Utilization efficiency metrics

### Student Outcomes
- Academic performance metrics
- Standardized test scores
- Progress tracking over time
- School-wide performance indicators

### Parent Involvement
- Participation in school activities
- Volunteer hours and contributions
- Communication frequency
- Engagement quality metrics

## Security Considerations

- Access control for sensitive operations
- Data validation and error handling
- Audit trails for all transactions
- Privacy protection for student data

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or support, please open an issue in the repository or contact the development team.
