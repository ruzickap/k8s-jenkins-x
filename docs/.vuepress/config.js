module.exports = {
  title: 'Kubernetes + Jenkins X + Sock Shop',
  description: 'Kubernetes + Jenkins X + Sock Shop',
  base: '/k8s-jenkins-x/',
  head: [
    ['link', { rel: 'icon', href: 'https://raw.githubusercontent.com/kubernetes/kubernetes/d9a58a39b69a0eaec5797e0f7a0f9472b4829ab0/logo/logo.svg' }]
  ],
  themeConfig: {
    displayAllHeaders: true,
    lastUpdated: true,
    repo: 'ruzickap/k8s-jenkins-x',
    docsDir: 'docs',
    editLinks: true,
    logo: 'https://raw.githubusercontent.com/kubernetes/kubernetes/d9a58a39b69a0eaec5797e0f7a0f9472b4829ab0/logo/logo.svg',
    nav: [
      { text: 'Home', link: '/' },
      {
        text: 'Links',
        items: [
          { text: 'Jenkins X', link: 'https://jenkins-x.io/' }
        ]
      }
    ],
    sidebar: [
      '/',
      '/part-01/',
      '/part-02/',
      '/part-03/',
      '/part-04/'
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
