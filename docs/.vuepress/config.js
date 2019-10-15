module.exports = {
  title: "Kubernetes + Jenkins X + Sock Shop",
  description: "Kubernetes + Jenkins X + Sock Shop",
  base: '/k8s-jenkins-x/',
  head: [
    ['link', { rel: "icon", href: "https://kubernetes.io/images/favicon.png" }]
  ],
  themeConfig: {
    displayAllHeaders: true,
    lastUpdated: true,
    repo: 'ruzickap/k8s-jenkins-x',
    docsDir: 'docs',
    editLinks: true,
    logo: 'https://kubernetes.io/images/favicon.png',
    nav: [
      { text: 'Home', link: '/' },
      {
        text: 'Links',
        items: [
          { text: 'Jenkins X', link: 'https://jenkins-x.io/' },
        ]
      }
    ],
    sidebar: [
      '/',
      '/part-01/',
    ]
  },
  plugins: [
    ['@vuepress/medium-zoom'],
    ['@vuepress/back-to-top'],
    ['reading-progress'],
    ['smooth-scroll'],
    ['seo']
  ]
}
