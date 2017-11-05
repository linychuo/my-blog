import { h, Component } from 'preact';
import { Link } from 'preact-router/match';
import style from './style';
import config from '../../config';
import cx from 'classnames';

const Col1 = () => (
	<div class={cx(style.footer_col, style.footer_col_1)}>
    	<ul class={style.contact_list}>
      		<li>{config.title}</li>
      		<li><a href="mailto:{config.email}">{config.email}</a></li>
    	</ul>
  	</div>
);

const Col2 = () => (
	<div class={cx(style.footer_col, style.footer_col_2)}>
        <ul class={style.social_media_list}>
        	{config.socialSites.map(site => 
        	<li>
	            <a href={site.url}>
	              <span class={style.icon}>
	                <svg viewBox="0 0 16 16">
	                  <path fill="#828282" d={site.icon}></path>
	                </svg>
	              </span>
	              <span> {site.userName}</span>
	            </a>
	        </li>
	    	)}
        </ul>
    </div>
);

export default class Footer extends Component {
	render() {
		return (
			<footer class={style.footer}>
				<div class="wrapper">
					<div class={style.footer_col_wrapper}>
						<Col1/>
						<Col2/>
					</div>
				</div>
			</footer>
		);
	}
}