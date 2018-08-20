import { MemoryRouter } from 'react-router';
import { Route, Link } from 'react-router-dom';
import Header from './header';
import Footer from './footer';
import Article from '../routes/article';
import config from '../config';

const Home = () => (
	<div class="page-content">
		<div class="wrapper">
			<div>
				<ul class="post-list">
					{config.articles.filter(article => article.showOnMain).map(article => (
						<li>
							<span class="post-meta">{article.created}</span>
							<h2><Link class="post-link" to={`/article/${article.name}`}>{article.name}</Link></h2>
						</li>
					))}
				</ul>
			</div>
		</div>
	</div>
);


const App = () => (
	<MemoryRouter>
		<div>
			<Header />
			<Route path="/" component={Home} />
			<Route path="/article/:name" component={Article} />
			<Footer />
		</div>
	</MemoryRouter>
);

export default App;
